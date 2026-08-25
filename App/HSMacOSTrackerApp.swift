import SwiftUI

@main
struct HSMacOSTrackerApp: App {
    @StateObject private var model = AppModel()
    private let overlayController = OverlayPanelController()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .onAppear {
                    model.refreshEnvironment()
                    overlayController.setVisible(model.overlayVisible, model: model)
                }
                .onChange(of: model.overlayVisible) { _, visible in
                    overlayController.setVisible(visible, model: model)
                }
                .onDisappear {
                    model.stopTailing()
                    overlayController.setVisible(false, model: model)
                }
        }

        Settings {
            SettingsView(model: model)
        }
    }
}
