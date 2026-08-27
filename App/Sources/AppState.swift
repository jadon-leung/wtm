import Foundation
import Observation
import WTMCore

@MainActor
@Observable
final class AppState {
    enum Phase {
        case launching
        case signedOut
        case needsOnboarding(WTMUser)
        case ready(WTMUser)
    }

    private(set) var phase: Phase = .launching
    private(set) var currentServices: ServiceContainer

    init(services: ServiceContainer) {
        self.currentServices = services
    }

    func bootstrap() async {
        guard case .launching = phase else { return }
        #if DEBUG
        // Launch-argument hook for screenshot/QA tooling, e.g.
        // `xcrun simctl launch <device> com.wtm.app --wtm-preview-main` —
        // lets us land directly on a given phase without tapping through
        // the debug skip buttons by hand. Compiled out of Release builds.
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--wtm-preview-main") {
            enterDebugMode(atOnboarding: false)
            return
        }
        if arguments.contains("--wtm-preview-onboarding") {
            enterDebugMode(atOnboarding: true)
            return
        }
        #endif
        guard let user = await currentServices.auth.currentUser() else {
            phase = .signedOut
            return
        }
        await route(after: user)
    }

    func handleSignedIn(_ user: WTMUser) {
        Task { await route(after: user) }
    }

    func completeOnboarding(for user: WTMUser) {
        phase = .ready(user)
    }

    func signOut() {
        Task {
            try? await currentServices.auth.signOut()
            phase = .signedOut
        }
    }

    #if DEBUG
    /// Fast lane for UI iteration: skips real auth entirely, switches every
    /// downstream service to in-memory mocks, and jumps straight to the
    /// requested phase. Compiled out of Release builds.
    func enterDebugMode(atOnboarding: Bool) {
        currentServices = .mock
        let user = MockAuthService.sampleUser
        phase = atOnboarding ? .needsOnboarding(user) : .ready(user)
    }
    #endif

    private func route(after user: WTMUser) async {
        let existingPreferences = (try? await currentServices.preferences.fetch(userID: user.id)) ?? nil
        phase = existingPreferences != nil ? .ready(user) : .needsOnboarding(user)
    }
}
