import Foundation
import Testing
import WTMCore
@testable import Groups

@Suite
struct GroupsViewModelTests {
    @Test
    func creatingAGroupPrependsItToTheList() async {
        let viewModel = GroupsViewModel(groupService: MockGroupService())
        let group = await viewModel.createGroup(name: "Friday Crew")

        #expect(group != nil)
        #expect(viewModel.groups.first?.id == group?.id)
    }
}
