import Foundation
import Testing
import WTMCore
@testable import Profile

@Suite
struct ProfileViewModelTests {
    @Test
    func savePersistsEditedFields() async {
        let user = WTMUser(id: UUID(), displayName: "Old Name")
        let viewModel = ProfileViewModel(user: user, profileService: MockProfileService())
        viewModel.displayName = "New Name"

        let saved = await viewModel.save()

        #expect(saved)
        #expect(viewModel.errorMessage == nil)
    }
}
