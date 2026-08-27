import Foundation

public protocol GroupServicing: Sendable {
    /// Groups the current user belongs to.
    func myGroups() async throws -> [WTMGroup]
    func createGroup(name: String) async throws -> WTMGroup
    func joinGroup(inviteCode: String) async throws -> WTMGroup
    func members(of groupID: UUID) async throws -> [WTMUser]

    /// Read-only itinerary preview for someone who followed an invite link
    /// but hasn't joined the group (or isn't signed in) yet.
    func previewItinerary(inviteCode: String) async throws -> Itinerary?
}
