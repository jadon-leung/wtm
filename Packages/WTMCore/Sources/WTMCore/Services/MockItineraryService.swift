import Foundation

/// In-memory stand-in for the itinerary engine. Generates a plausible
/// sample itinerary so the ItineraryPlanner UI has something real to render
/// and swap against before the actual engine exists.
public actor MockItineraryService: ItineraryServicing {
    private var itinerariesByGroupID: [UUID: Itinerary] = [:]

    public init() {}

    public func fetchItinerary(for groupID: UUID) async throws -> Itinerary? {
        itinerariesByGroupID[groupID]
    }

    public func generateItinerary(for groupID: UUID) async throws -> Itinerary {
        try? await Task.sleep(for: .seconds(1.2))
        let itinerary = Self.sampleItinerary(groupID: groupID)
        itinerariesByGroupID[groupID] = itinerary
        return itinerary
    }

    public func swapStop(
        _ stopID: UUID,
        in itinerary: Itinerary,
        forAlternate alternate: VenueAlternate
    ) async throws -> ItineraryStop {
        guard
            var stored = itinerariesByGroupID[itinerary.groupID],
            let index = stored.stops.firstIndex(where: { $0.id == stopID })
        else {
            throw APIError.notFound
        }

        var stop = stored.stops[index]
        let previousVenue = stop.venue
        stop.venue = alternate.venue
        stop.alternates = stop.alternates
            .filter { $0.venue.id != alternate.venue.id }
            + [VenueAlternate(venue: previousVenue, rank: alternate.rank)]

        stored.stops[index] = stop
        itinerariesByGroupID[itinerary.groupID] = stored
        return stop
    }

    public func submitFeedback(stopID: UUID, action: FeedbackAction) async throws {
        // No-op: nothing persists this yet, there's no backend for it.
    }

    private static func sampleItinerary(groupID: UUID) -> Itinerary {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        func time(_ hour: Int, _ minute: Int = 0) -> Date {
            calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) ?? .now
        }

        func venue(_ name: String, _ category: String, price: Int, rating: Double, address: String) -> Venue {
            Venue(
                id: UUID(),
                source: .googlePlaces,
                externalID: UUID().uuidString,
                name: name,
                category: category,
                priceLevel: price,
                rating: rating,
                address: address
            )
        }

        let stopDefinitions: [(String, String, [(String, String, Int, Double, String)])] = [
            (
                "Lunch", "Restaurant",
                [
                    ("Marlowe's Kitchen", "New American", 2, 4.6, "412 5th Ave"),
                    ("Taqueria Sol", "Mexican", 1, 4.4, "88 Union St"),
                    ("Ginger & Basil", "Thai", 2, 4.5, "210 Market St")
                ]
            ),
            (
                "Coffee", "Cafe",
                [
                    ("Half Moon Coffee", "Cafe", 1, 4.7, "55 Vine St"),
                    ("The Grind House", "Cafe", 1, 4.3, "19 Pearl St")
                ]
            ),
            (
                "Activity", "Entertainment",
                [
                    ("Riverside Mini Golf", "Entertainment", 2, 4.2, "300 Harbor Dr"),
                    ("City Arcade", "Entertainment", 2, 4.1, "77 Broad St"),
                    ("Skyline Bowling", "Entertainment", 2, 4.4, "150 Union St")
                ]
            ),
            (
                "Dinner & Drinks", "Bar",
                [
                    ("The Wren", "Cocktail Bar", 3, 4.8, "9 Landing Way"),
                    ("Corner Tap House", "Bar", 2, 4.3, "64 Elm St")
                ]
            )
        ]

        let startHours = [12, 14, 15, 18]
        let durationsInMinutes = [75, 45, 90, 120]

        var stops: [ItineraryStop] = []
        for (index, definition) in stopDefinitions.enumerated() {
            let (_, category, options) = definition
            let venues = options.map { venue($0.0, $0.1, price: $0.2, rating: $0.3, address: $0.4) }
            let start = time(startHours[index])
            let end = calendar.date(byAdding: .minute, value: durationsInMinutes[index], to: start) ?? start

            let alternates = venues.dropFirst().enumerated().map { offset, alt in
                VenueAlternate(venue: alt, rank: offset + 1)
            }

            stops.append(
                ItineraryStop(
                    id: UUID(),
                    itineraryID: UUID(),
                    order: index,
                    startTime: start,
                    endTime: end,
                    venue: venues[0],
                    alternates: Array(alternates)
                )
            )
            _ = category
        }

        let itineraryID = UUID()
        let stopsWithItineraryID = stops.map { stop -> ItineraryStop in
            var stop = stop
            stop.itineraryID = itineraryID
            return stop
        }

        return Itinerary(
            id: itineraryID,
            groupID: groupID,
            status: .ready,
            generatedAt: .now,
            stops: stopsWithItineraryID
        )
    }
}
