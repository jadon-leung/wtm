import Foundation

public enum BudgetTier: String, Codable, Sendable, CaseIterable, Identifiable {
    case low
    case medium
    case high
    case noPreference = "no_preference"

    public var id: Self { self }

    public var label: String {
        switch self {
        case .low: "$"
        case .medium: "$$"
        case .high: "$$$"
        case .noPreference: "Any"
        }
    }
}

public enum ActivityType: String, Codable, Sendable, CaseIterable, Identifiable {
    case food
    case drinks
    case outdoors
    case entertainment
    case culture
    case active
    case nightlife

    public var id: Self { self }

    public var label: String {
        switch self {
        case .food: "Food"
        case .drinks: "Drinks"
        case .outdoors: "Outdoors"
        case .entertainment: "Entertainment"
        case .culture: "Culture"
        case .active: "Active"
        case .nightlife: "Nightlife"
        }
    }
}

public struct UserPreferences: Codable, Sendable, Hashable {
    public var userID: UUID
    public var cuisines: [String]
    public var budgetTier: BudgetTier
    public var activityTypes: [ActivityType]
    public var dietaryRestrictions: [String]

    public init(
        userID: UUID,
        cuisines: [String] = [],
        budgetTier: BudgetTier = .noPreference,
        activityTypes: [ActivityType] = [],
        dietaryRestrictions: [String] = []
    ) {
        self.userID = userID
        self.cuisines = cuisines
        self.budgetTier = budgetTier
        self.activityTypes = activityTypes
        self.dietaryRestrictions = dietaryRestrictions
    }

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case cuisines
        case budgetTier = "budget_tier"
        case activityTypes = "activity_types"
        case dietaryRestrictions = "dietary_restrictions"
    }
}
