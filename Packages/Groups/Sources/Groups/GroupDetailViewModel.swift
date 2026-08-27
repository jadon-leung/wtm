import Foundation
import Observation
import WTMCore

@MainActor
@Observable
public final class GroupDetailViewModel {
    public var members: [WTMUser] = []
    public var isLoading = false
    public var errorMessage: String?

    private let group: WTMGroup
    private let groupService: any GroupServicing

    public init(group: WTMGroup, groupService: any GroupServicing) {
        self.group = group
        self.groupService = groupService
    }

    public func loadMembers() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            members = try await groupService.members(of: group.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
