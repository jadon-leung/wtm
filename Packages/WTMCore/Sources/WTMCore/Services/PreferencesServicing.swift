import Foundation

public protocol PreferencesServicing: Sendable {
    func fetch(userID: UUID) async throws -> UserPreferences?
    func save(_ preferences: UserPreferences) async throws
}
