import Foundation
import Observation
import WTMCore

@MainActor
@Observable
public final class GroupsViewModel {
    public var groups: [WTMGroup] = []
    public var isLoading = false
    public var errorMessage: String?

    private let groupService: any GroupServicing

    public init(groupService: any GroupServicing) {
        self.groupService = groupService
    }

    public func loadGroups() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            groups = try await groupService.myGroups()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func createGroup(name: String) async -> WTMGroup? {
        errorMessage = nil
        do {
            let group = try await groupService.createGroup(name: name)
            groups.insert(group, at: 0)
            return group
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    public func joinGroup(inviteCode: String) async -> WTMGroup? {
        errorMessage = nil
        do {
            let group = try await groupService.joinGroup(inviteCode: inviteCode)
            if !groups.contains(where: { $0.id == group.id }) {
                groups.insert(group, at: 0)
            }
            return group
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
