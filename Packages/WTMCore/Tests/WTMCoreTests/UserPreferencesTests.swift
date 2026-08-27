import Foundation
import Testing
@testable import WTMCore

@Suite
struct UserPreferencesTests {
    @Test
    func defaultsToNoPreference() {
        let preferences = UserPreferences(userID: UUID())
        #expect(preferences.budgetTier == .noPreference)
        #expect(preferences.cuisines.isEmpty)
    }
}
