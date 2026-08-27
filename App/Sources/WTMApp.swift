import SwiftUI
import WTMCore

@main
struct WTMApp: App {
    @State private var appState = AppState(services: .live)

    init() {
        // SwiftUI runs App.init() on the main thread at launch, but the
        // compiler can't statically prove that from the App protocol's
        // (non-isolated) init requirement — assumeIsolated bridges that gap
        // rather than making configure() itself non-isolated.
        MainActor.assumeIsolated {
            AppearanceConfigurator.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Theme.Colors.coral)
                .environment(appState)
        }
    }
}
