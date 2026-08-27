import Foundation

/// No live implementation yet — the itinerary engine (a separate Python
/// service per the architecture doc) doesn't exist. `MockItineraryService`
/// is the only conformance for now; swap in a real HTTP-backed
/// implementation once that service has an endpoint to call.
public protocol ItineraryServicing: Sendable {
    func fetchItinerary(for groupID: UUID) async throws -> Itinerary?
    func generateItinerary(for groupID: UUID) async throws -> Itinerary
    func swapStop(_ stopID: UUID, in itinerary: Itinerary, forAlternate alternate: VenueAlternate) async throws -> ItineraryStop
    func submitFeedback(stopID: UUID, action: FeedbackAction) async throws

    /// Inserts a stop at `index` in the itinerary's ordering, pushing any
    /// later stops' times forward just enough to avoid overlapping it.
    func insertStop(_ venue: Venue, into itinerary: Itinerary, at index: Int, startTime: Date, endTime: Date) async throws -> Itinerary
    func removeStop(_ stopID: UUID, from itinerary: Itinerary) async throws -> Itinerary
}
