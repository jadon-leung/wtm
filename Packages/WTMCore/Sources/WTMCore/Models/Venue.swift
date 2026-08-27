import Foundation

public enum VenueSource: String, Codable, Sendable {
    case googlePlaces = "google_places"
    case yelp
}

public struct Venue: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var source: VenueSource
    public var externalID: String
    public var name: String
    public var category: String
    public var priceLevel: Int?
    public var rating: Double?
    public var address: String?
    public var lat: Double?
    public var lng: Double?
    public var photoURLs: [String]

    public init(
        id: UUID,
        source: VenueSource,
        externalID: String,
        name: String,
        category: String,
        priceLevel: Int? = nil,
        rating: Double? = nil,
        address: String? = nil,
        lat: Double? = nil,
        lng: Double? = nil,
        photoURLs: [String] = []
    ) {
        self.id = id
        self.source = source
        self.externalID = externalID
        self.name = name
        self.category = category
        self.priceLevel = priceLevel
        self.rating = rating
        self.address = address
        self.lat = lat
        self.lng = lng
        self.photoURLs = photoURLs
    }

    enum CodingKeys: String, CodingKey {
        case id
        case source
        case externalID = "external_id"
        case name
        case category
        case priceLevel = "price_level"
        case rating
        case address
        case lat
        case lng
        case photoURLs = "photo_urls"
    }
}
