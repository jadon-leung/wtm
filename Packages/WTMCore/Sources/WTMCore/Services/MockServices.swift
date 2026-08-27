import Foundation

// Lightweight in-memory conformances used for `ServiceContainer.mock` —
// SwiftUI previews and anywhere else that shouldn't touch the network.

public actor MockAuthService: AuthServicing {
    public static let sampleUser = WTMUser(
        id: UUID(),
        displayName: "Jordan Lee",
        phone: "+15555550123",
        email: "jordan@example.com"
    )

    private var signedInUser: WTMUser?

    public init(signedInUser: WTMUser? = nil) {
        self.signedInUser = signedInUser
    }

    public func currentUser() async -> WTMUser? { signedInUser }

    public func signInWithApple(identityToken: String, nonce: String, fullName: String?) async throws -> WTMUser {
        let user = WTMUser(id: UUID(), displayName: fullName ?? "New User")
        signedInUser = user
        return user
    }

    public func signInWithEmail(email: String, password: String) async throws -> WTMUser {
        let user = WTMUser(id: UUID(), email: email)
        signedInUser = user
        return user
    }

    public func signUpWithEmail(email: String, password: String) async throws -> WTMUser {
        try await signInWithEmail(email: email, password: password)
    }

    public func requestPhoneCode(phone: String) async throws {}

    public func verifyPhoneCode(phone: String, code: String) async throws -> WTMUser {
        let user = WTMUser(id: UUID(), phone: phone)
        signedInUser = user
        return user
    }

    public func continueAsGuest() async throws -> WTMUser {
        let user = WTMUser(id: UUID(), displayName: "Guest", isGuest: true)
        signedInUser = user
        return user
    }

    public func signOut() async throws {
        signedInUser = nil
    }
}

public actor MockPreferencesService: PreferencesServicing {
    private var stored: [UUID: UserPreferences] = [:]

    public init() {}

    public func fetch(userID: UUID) async throws -> UserPreferences? {
        stored[userID]
    }

    public func save(_ preferences: UserPreferences) async throws {
        stored[preferences.userID] = preferences
    }
}

public actor MockGroupService: GroupServicing {
    private var groups: [WTMGroup] = []

    public init() {}

    public func myGroups() async throws -> [WTMGroup] {
        groups
    }

    public func createGroup(name: String) async throws -> WTMGroup {
        let group = WTMGroup(
            id: UUID(),
            name: name,
            createdBy: MockAuthService.sampleUser.id,
            inviteCode: String(UUID().uuidString.prefix(6))
        )
        groups.append(group)
        return group
    }

    public func joinGroup(inviteCode: String) async throws -> WTMGroup {
        if let existing = groups.first(where: { $0.inviteCode == inviteCode }) {
            return existing
        }
        let group = WTMGroup(
            id: UUID(),
            name: "Joined Group",
            createdBy: UUID(),
            inviteCode: inviteCode
        )
        groups.append(group)
        return group
    }

    public func members(of groupID: UUID) async throws -> [WTMUser] {
        [MockAuthService.sampleUser]
    }

    public func previewItinerary(inviteCode: String) async throws -> Itinerary? {
        nil
    }
}

public actor MockProfileService: ProfileServicing {
    public init() {}

    public func fetch(userID: UUID) async throws -> WTMUser {
        MockAuthService.sampleUser
    }

    public func update(_ user: WTMUser) async throws {}
}
