import Foundation
import Testing
import WTMCore
@testable import Preferences

@Suite
struct PreferencesViewModelTests {
    @Test
    func togglingACuisineAddsAndRemovesIt() async {
        let viewModel = PreferencesViewModel(userID: UUID(), preferencesService: MockPreferencesService())
        viewModel.toggleCuisine("Thai")
        #expect(viewModel.selectedCuisines.contains("Thai"))

        viewModel.toggleCuisine("Thai")
        #expect(!viewModel.selectedCuisines.contains("Thai"))
    }

    @Test
    func saveRoundTripsThroughTheService() async {
        let service = MockPreferencesService()
        let userID = UUID()
        let viewModel = PreferencesViewModel(userID: userID, preferencesService: service)
        viewModel.budgetTier = .medium
        viewModel.toggleActivityType(.food)

        let saved = await viewModel.save()
        #expect(saved)

        let fetched = try? await service.fetch(userID: userID)
        #expect(fetched?.budgetTier == .medium)
        #expect(fetched?.activityTypes == [.food])
    }
}
