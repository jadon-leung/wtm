import Foundation

public enum FeedbackAction: String, Codable, Sendable {
    case accepted
    case rejected
    case swapped
}

public struct StopFeedback: Identifiable, Codable, Sendable, Hashable {
    public var id: String { "\(itineraryStopID)-\(userID)" }
    public var itineraryStopID: UUID
    public var userID: UUID
    public var action: FeedbackAction

    public init(itineraryStopID: UUID, userID: UUID, action: FeedbackAction) {
        self.itineraryStopID = itineraryStopID
        self.userID = userID
        self.action = action
    }

    enum CodingKeys: String, CodingKey {
        case itineraryStopID = "itinerary_stop_id"
        case userID = "user_id"
        case action
    }
}
