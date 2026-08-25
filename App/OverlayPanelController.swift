import AppKit
import HSMacOSTrackerLib
import SwiftUI

@MainActor
final class OverlayPanelController: NSObject {
    private var panel: NSPanel?
    private var timer: Timer?
    private weak var model: AppModel?

    func setVisible(_ visible: Bool, model: AppModel) {
        self.model = model
        if visible {
            show(model: model)
            startFollowing()
        } else {
            timer?.invalidate()
            timer = nil
            panel?.orderOut(nil)
        }
    }

    private func show(model: AppModel) {
        if panel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 120, y: 120, width: 300, height: 360),
                styleMask: [.nonactivatingPanel, .hudWindow, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = true
            panel.ignoresMouseEvents = true
            panel.titleVisibility = .hidden
            panel.titlebarAppearsTransparent = true
            panel.isMovableByWindowBackground = true
            panel.hidesOnDeactivate = false
            self.panel = panel
        }

        panel?.contentView = NSHostingView(rootView: OverlayView(model: model))
        panel?.orderFrontRegardless()
        dockToGameWindow()
    }

    private func startFollowing() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.dockToGameWindow()
            }
        }
    }

    private func dockToGameWindow() {
        model?.refreshGameWindow()
        guard let panel, let quartz = GameWindowLocator.locate()?.quartzBounds else { return }
        let primaryHeight = NSScreen.screens.first { $0.frame.origin == .zero }?.frame.height
            ?? NSScreen.main?.frame.height
            ?? 0
        let game = OverlayLayout.appKitRect(quartz: quartz, primaryHeight: primaryHeight)
        let screens = NSScreen.screens.map(\.frame)
        let screen = OverlayLayout.screenContaining(
            point: CGPoint(x: game.midX, y: game.midY),
            screens: screens,
            fallback: NSScreen.main?.frame ?? game
        )
        let frame = OverlayLayout.dock(game: game, overlaySize: panel.frame.size, screen: screen)
        panel.setFrame(frame, display: true)
    }
}

struct OverlayView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HS macOS Tracker")
                .font(.headline)
            Text("Build: \(model.gameBuildLabel)")
            Text("HS window: \(model.gameWindowLabel)")
            Text("Turn: \(model.publicView.turn.map(String.init) ?? "unknown")")
            if model.featureFlags.arenaEnabled {
                Text("Arena: \(model.arenaPhase.rawValue)")
                if let advice = model.arenaAdvice {
                    Text("Pick: \(advice.pick.name)")
                        .fontWeight(.semibold)
                    Text("Alt: \(advice.runnerUp.name)")
                        .font(.caption)
                }
            }
            if model.featureFlags.adviceEnabled {
                ForEach(model.adviceLines.prefix(4)) { line in
                    Text(line.text)
                        .font(.caption)
                }
            }
            if !model.publicView.remainingKnown {
                Text("Remaining: unknown")
            } else {
                ForEach(model.publicView.remainingRows.prefix(8)) { row in
                    HStack {
                        Text("\(row.name) ×\(row.count)")
                        Spacer()
                        if let odds = row.nextDraw {
                            Text(String(format: "%.0f%%", odds * 100))
                        }
                    }
                    .font(.caption)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
