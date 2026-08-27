import Onboarding
import Preferences
import SwiftUI
import WTMCore

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        content
            .environment(\.services, appState.currentServices)
            .task { await appState.bootstrap() }
    }

    @ViewBuilder
    private var content: some View {
        switch appState.phase {
        case .launching:
            ProgressView()

        case .signedOut:
            #if DEBUG
            SignInView(
                onSignedIn: { user in appState.handleSignedIn(user) },
                onDebugSkipToPreferences: { appState.enterDebugMode(atOnboarding: true) },
                onDebugSkipToMainApp: { appState.enterDebugMode(atOnboarding: false) }
            )
            #else
            SignInView(onSignedIn: { user in appState.handleSignedIn(user) })
            #endif

        case .needsOnboarding(let user):
            PreferencesView(user: user, onSaved: { appState.completeOnboarding(for: user) })

        case .ready(let user):
            MainTabView(currentUser: user, onSignOut: { appState.signOut() })
        }
    }
}
