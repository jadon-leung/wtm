import Foundation
import Observation
import WTMCore

@MainActor
@Observable
public final class PreferencesViewModel {
    public var selectedCuisines: Set<String> = []
    public var budgetTier: BudgetTier = .noPreference
    public var selectedActivityTypes: Set<ActivityType> = []
    public var selectedDietaryRestrictions: Set<String> = []

    public var isLoading = false
    public var isSaving = false
    public var errorMessage: String?

    private let userID: UUID
    private let preferencesService: any PreferencesServicing

    public init(userID: UUID, preferencesService: any PreferencesServicing) {
        self.userID = userID
        self.preferencesService = preferencesService
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            guard let existing = try await preferencesService.fetch(userID: userID) else { return }
            selectedCuisines = Set(existing.cuisines)
            budgetTier = existing.budgetTier
            selectedActivityTypes = Set(existing.activityTypes)
            selectedDietaryRestrictions = Set(existing.dietaryRestrictions)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    public func save() async -> Bool {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            let preferences = UserPreferences(
                userID: userID,
                cuisines: Array(selectedCuisines),
                budgetTier: budgetTier,
                activityTypes: Array(selectedActivityTypes),
                dietaryRestrictions: Array(selectedDietaryRestrictions)
            )
            try await preferencesService.save(preferences)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    public func toggleCuisine(_ cuisine: String) {
        toggle(cuisine, in: &selectedCuisines)
    }

    public func toggleActivityType(_ type: ActivityType) {
        toggle(type, in: &selectedActivityTypes)
    }

    public func toggleDietaryRestriction(_ restriction: String) {
        toggle(restriction, in: &selectedDietaryRestrictions)
    }

    private func toggle<T>(_ value: T, in set: inout Set<T>) {
        if set.contains(value) {
            set.remove(value)
        } else {
            set.insert(value)
        }
    }
}
