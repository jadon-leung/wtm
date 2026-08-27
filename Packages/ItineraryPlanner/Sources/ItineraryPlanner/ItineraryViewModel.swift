import Foundation
import Observation
import WTMCore

@MainActor
@Observable
public final class ItineraryViewModel {
    public var itinerary: Itinerary?
    public var isLoading = false
    public var isGenerating = false
    public var errorMessage: String?

    private let group: WTMGroup
    private let itineraryService: any ItineraryServicing

    public init(group: WTMGroup, itineraryService: any ItineraryServicing) {
        self.group = group
        self.itineraryService = itineraryService
    }

    public func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            itinerary = try await itineraryService.fetchItinerary(for: group.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func generate() async {
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }
        do {
            itinerary = try await itineraryService.generateItinerary(for: group.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func swap(stop: ItineraryStop, forAlternate alternate: VenueAlternate) async {
        guard let itinerary else { return }
        errorMessage = nil
        do {
            let updatedStop = try await itineraryService.swapStop(stop.id, in: itinerary, forAlternate: alternate)
            if let index = self.itinerary?.stops.firstIndex(where: { $0.id == updatedStop.id }) {
                self.itinerary?.stops[index] = updatedStop
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func submitFeedback(stop: ItineraryStop, action: FeedbackAction) async {
        try? await itineraryService.submitFeedback(stopID: stop.id, action: action)
    }

    /// Inserts a manually-entered stop at `index` in the current itinerary's
    /// ordering. `index == 0` inserts before everything (timed to arrive
    /// right as the current first stop starts); `index >= stops.count`
    /// appends after the last stop.
    public func insertStop(named name: String, category: String, durationMinutes: Int, at index: Int) async {
        guard let itinerary else { return }
        errorMessage = nil

        let travelBuffer: TimeInterval = 15 * 60
        let duration = TimeInterval(durationMinutes * 60)
        let sortedStops = itinerary.stops.sorted { $0.order < $1.order }

        let start: Date
        if index <= 0 {
            start = (sortedStops.first?.startTime ?? .now).addingTimeInterval(-(duration + travelBuffer))
        } else {
            let anchor = sortedStops[min(index, sortedStops.count) - 1]
            start = anchor.endTime.addingTimeInterval(travelBuffer)
        }
        let end = start.addingTimeInterval(duration)

        let venue = Venue(
            id: UUID(),
            source: .googlePlaces,
            externalID: UUID().uuidString,
            name: name,
            category: category
        )

        do {
            self.itinerary = try await itineraryService.insertStop(venue, into: itinerary, at: index, startTime: start, endTime: end)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func removeStop(_ stop: ItineraryStop) async {
        guard let itinerary else { return }
        errorMessage = nil
        do {
            self.itinerary = try await itineraryService.removeStop(stop.id, from: itinerary)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
