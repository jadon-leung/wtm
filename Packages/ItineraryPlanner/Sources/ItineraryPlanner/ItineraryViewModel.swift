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
}
