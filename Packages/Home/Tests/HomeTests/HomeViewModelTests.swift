import Foundation
import Testing
import WTMCore
@testable import Home

@Suite
struct HomeViewModelTests {
    @Test
    func loadSurfacesReadyItineraryAsNextUp() async throws {
        let groupService = MockGroupService()
        let itineraryService = MockItineraryService()
        let group = try await groupService.createGroup(name: "Silver Lake Crew")
        _ = try await itineraryService.generateItinerary(for: group.id)

        let viewModel = HomeViewModel(
            currentUserID: UUID(),
            groupService: groupService,
            itineraryService: itineraryService
        )
        await viewModel.load()

        #expect(viewModel.groups.count == 1)
        #expect(viewModel.nextUp?.group.id == group.id)
        #expect(viewModel.pastPlans.isEmpty)
    }

    @Test
    func loadBucketsCompletedGroupsAsPastPlans() async throws {
        let groupService = MockGroupService()
        let itineraryService = MockItineraryService()
        var group = try await groupService.createGroup(name: "Beach Day")
        group.status = .completed

        let viewModel = HomeViewModel(
            currentUserID: UUID(),
            groupService: StubGroupService(groups: [group]),
            itineraryService: itineraryService
        )
        await viewModel.load()

        #expect(viewModel.nextUp == nil)
        #expect(viewModel.pastPlans.map(\.group.id) == [group.id])
    }
}

private actor StubGroupService: GroupServicing {
    private let groups: [WTMGroup]

    init(groups: [WTMGroup]) {
        self.groups = groups
    }

    func myGroups() async throws -> [WTMGroup] { groups }
    func createGroup(name: String) async throws -> WTMGroup { groups[0] }
    func joinGroup(inviteCode: String) async throws -> WTMGroup { groups[0] }
    func members(of groupID: UUID) async throws -> [WTMUser] { [] }
    func previewItinerary(inviteCode: String) async throws -> Itinerary? { nil }
}
