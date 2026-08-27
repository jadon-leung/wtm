import Foundation

public enum ItineraryStatus: String, Codable, Sendable {
    case draft
    case generating
    case ready
    case failed
}

/// App-layer composed view of an itinerary: joins `itineraries` with its
/// stops, each stop's venue, and that stop's ranked alternates. Not a 1:1
/// mirror of any single table — once the itinerary engine exists, the
/// service layer is responsible for assembling this shape (e.g. via an RPC
/// that returns nested JSON, or a few queries stitched together client-side).
public struct Itinerary: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var groupID: UUID
    public var status: ItineraryStatus
    public var generatedAt: Date?
    public var stops: [ItineraryStop]

    public init(
        id: UUID,
        groupID: UUID,
        status: ItineraryStatus = .draft,
        generatedAt: Date? = nil,
        stops: [ItineraryStop] = []
    ) {
        self.id = id
        self.groupID = groupID
        self.status = status
        self.generatedAt = generatedAt
        self.stops = stops
    }

    enum CodingKeys: String, CodingKey {
        case id
        case groupID = "group_id"
        case status
        case generatedAt = "generated_at"
        case stops
    }
}

public struct ItineraryStop: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var itineraryID: UUID
    public var order: Int
    public var startTime: Date
    public var endTime: Date
    public var venue: Venue
    public var alternates: [VenueAlternate]

    public init(
        id: UUID,
        itineraryID: UUID,
        order: Int,
        startTime: Date,
        endTime: Date,
        venue: Venue,
        alternates: [VenueAlternate] = []
    ) {
        self.id = id
        self.itineraryID = itineraryID
        self.order = order
        self.startTime = startTime
        self.endTime = endTime
        self.venue = venue
        self.alternates = alternates
    }

    enum CodingKeys: String, CodingKey {
        case id
        case itineraryID = "itinerary_id"
        case order = "stop_order"
        case startTime = "start_time"
        case endTime = "end_time"
        case venue
        case alternates
    }
}

public struct VenueAlternate: Identifiable, Codable, Sendable, Hashable {
    public var id: UUID { venue.id }
    public var venue: Venue
    public var rank: Int
    public var score: Double?

    public init(venue: Venue, rank: Int, score: Double? = nil) {
        self.venue = venue
        self.rank = rank
        self.score = score
    }
}
