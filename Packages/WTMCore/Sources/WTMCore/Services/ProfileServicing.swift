import Foundation

public protocol ProfileServicing: Sendable {
    func fetch(userID: UUID) async throws -> WTMUser
    func update(_ user: WTMUser) async throws
}
