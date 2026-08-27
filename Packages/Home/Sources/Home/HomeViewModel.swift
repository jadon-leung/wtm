import Foundation
import Observation
import WTMCore

@MainActor
@Observable
public final class HomeViewModel {
    public struct UpcomingPlan {
        public let group: WTMGroup
        public let itinerary: Itinerary
        public let companionNames: [String]
    }

    public struct PastPlan: Identifiable {
        public var id: UUID { group.id }
        public let group: WTMGroup
        public let itinerary: Itinerary?
    }

    public var groups: [WTMGroup] = []
    public var nextUp: UpcomingPlan?
    public var pastPlans: [PastPlan] = []
    public var isLoading = false
    public var errorMessage: String?

    private let currentUserID: UUID
    private let groupService: any GroupServicing
    private let itineraryService: any ItineraryServicing

    public init(currentUserID: UUID, groupService: any GroupServicing, itineraryService: any ItineraryServicing) {
        self.currentUserID = currentUserID
        self.groupService = groupService
        self.itineraryService = itineraryService
    }

    public func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetchedGroups = try await groupService.myGroups()
            groups = fetchedGroups

            var upcoming: UpcomingPlan?
            var past: [PastPlan] = []

            for group in fetchedGroups {
                let itinerary = try? await itineraryService.fetchItinerary(for: group.id)

                switch group.status {
                case .forming, .active:
                    if upcoming == nil, let itinerary, itinerary.status == .ready, !itinerary.stops.isEmpty {
                        let members = (try? await groupService.members(of: group.id)) ?? []
                        let companionNames = members
                            .filter { $0.id != currentUserID }
                            .compactMap { $0.displayName }
                        upcoming = UpcomingPlan(group: group, itinerary: itinerary, companionNames: companionNames)
                    }
                case .completed, .archived:
                    past.append(PastPlan(group: group, itinerary: itinerary))
                }
            }

            nextUp = upcoming
            pastPlans = past.sorted { $0.group.createdAt > $1.group.createdAt }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
