import HSMacOSTrackerLib
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var featureFlags = FeatureFlags()
    @Published private(set) var logDirectoryLabel = "unknown"
    @Published private(set) var gameWindowLabel = "unknown"
    @Published private(set) var gameBuildLabel = "unknown"
    @Published private(set) var screenCaptureLabel = ScreenCaptureGate.statusLabel()
    @Published var overlayVisible = true
    @Published var deckstringText = ""
    @Published var importError: String?
    @Published var friendlySeatText = ""
    @Published private(set) var publicView = PublicMatchView.project(MatchState(), catalog: .empty)
    @Published private(set) var arenaPhase = ArenaPhase.unknown
    @Published var arenaPickedText = ""
    @Published var arenaOffer = ["", "", ""]
    @Published var arenaParseError: String?
    @Published private(set) var arenaAdvice: ArenaAdvice?
    @Published private(set) var adviceLines: [AdviceLine] = []

    let tailService = MultiLogTailService()
    let catalog = CardCatalog.empty
    private var discovery: LogDiscovery?
    private var match = MatchState()
    private var parser = PowerLogParser()

    init() {
        tailService.onPowerLine = { [weak self] line in
            self?.ingestPowerLine(line)
        }
        tailService.onArenaLine = { [weak self] line in
            self?.ingestArenaLine(line)
        }
    }

    func refreshEnvironment() {
        screenCaptureLabel = ScreenCaptureGate.statusLabel()
        refreshGameWindow()
        if let discovery = LogPaths.discover() {
            self.discovery = discovery
            logDirectoryLabel = discovery.directory.path
            gameBuildLabel = GameBuildDetector.scanFile(at: discovery.loadingScreenLog) ?? "unknown"
            tailService.start(discovery: discovery)
        } else {
            discovery = nil
            logDirectoryLabel = "unknown"
            gameBuildLabel = "unknown"
            tailService.stop()
        }
        publish()
    }

    func stopTailing() {
        tailService.stop()
    }

    func importDeck() {
        importError = nil
        do {
            let deck = try Deckstring.decode(deckstringText)
            apply(.importDeck(deck.counts))
        } catch {
            importError = "invalid"
            apply(.gap)
        }
    }

    func applyFriendlySeat() {
        let trimmed = friendlySeatText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let seat = Int(trimmed), seat == 1 || seat == 2 else {
            parser.friendlyPlayerId = nil
            return
        }
        parser.friendlyPlayerId = seat
        apply(.setFriendlyPlayer(seat))
    }

    func ingestPowerLine(_ line: String) {
        for event in parser.feed(line) {
            guard let allowed = Visibility.allow(event) else { continue }
            apply(allowed)
        }
    }

    func ingestArenaLine(_ line: String) {
        arenaPhase = ArenaDraftDetector.detect(from: line, current: arenaPhase)
        if arenaPhase == .idle {
            arenaAdvice = nil
        }
    }

    func recommendArenaPick() {
        arenaParseError = nil
        arenaAdvice = nil
        let picked = arenaPickedText.split(whereSeparator: \.isNewline).compactMap { ArenaCard.parse(String($0)) }
        let parsedPickedLines = arenaPickedText.split(whereSeparator: \.isNewline).filter {
            !$0.trimmingCharacters(in: .whitespaces).isEmpty
        }
        if parsedPickedLines.count != picked.count {
            arenaParseError = "picked unknown"
            return
        }
        let offers = arenaOffer.compactMap(ArenaOffer.parse)
        guard offers.count == 3 else {
            arenaParseError = "offer unknown"
            return
        }
        guard let advice = ArenaScorer.advise(picked: picked, offers: offers) else {
            arenaParseError = picked.isEmpty ? "bucket unknown" : "need 3 cards"
            return
        }
        arenaAdvice = advice
    }

    private func apply(_ event: GameEvent) {
        match = MatchState.reduce(match, event)
        publish()
    }

    func refreshGameWindow() {
        if let window = GameWindowLocator.locate() {
            gameWindowLabel = "\(Int(window.quartzBounds.width))×\(Int(window.quartzBounds.height))"
        } else {
            gameWindowLabel = "unknown"
        }
    }

    func refreshAdvice() {
        adviceLines = featureFlags.adviceEnabled ? AdviceEngine.lines(from: publicView) : []
    }

    private func publish() {
        publicView = PublicMatchView.project(match, catalog: catalog)
        refreshAdvice()
    }
}
