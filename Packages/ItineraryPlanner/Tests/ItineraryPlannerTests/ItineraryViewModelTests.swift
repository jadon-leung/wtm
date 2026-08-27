import Foundation
import Testing
import WTMCore
@testable import ItineraryPlanner

@Suite
struct ItineraryViewModelTests {
    @Test
    func generatingProducesStopsWithAlternates() async {
        let group = WTMGroup(id: UUID(), name: "Test Group", createdBy: UUID(), inviteCode: "ABC123")
        let viewModel = ItineraryViewModel(group: group, itineraryService: MockItineraryService())

        await viewModel.generate()

        #expect(viewModel.itinerary != nil)
        #expect((viewModel.itinerary?.stops.count ?? 0) > 0)
    }

    @Test
    func swappingReplacesTheStopVenue() async {
        let group = WTMGroup(id: UUID(), name: "Test Group", createdBy: UUID(), inviteCode: "ABC123")
        let viewModel = ItineraryViewModel(group: group, itineraryService: MockItineraryService())
        await viewModel.generate()

        guard
            let stop = viewModel.itinerary?.stops.first(where: { !$0.alternates.isEmpty }),
            let alternate = stop.alternates.first
        else {
            Issue.record("Expected a stop with at least one alternate")
            return
        }

        await viewModel.swap(stop: stop, forAlternate: alternate)

        let updatedStop = viewModel.itinerary?.stops.first(where: { $0.id == stop.id })
        #expect(updatedStop?.venue.id == alternate.venue.id)
    }
}
