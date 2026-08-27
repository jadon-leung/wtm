import Foundation
import Supabase

public struct SupabaseGroupService: GroupServicing {
    private let client: SupabaseClient

    public init(client: SupabaseClient = SupabaseClientProvider.client) {
        self.client = client
    }

    public func myGroups() async throws -> [WTMGroup] {
        // RLS already scopes `groups` to rows the caller is a member of, so
        // this is a plain unfiltered select.
        try await client.from("groups")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    public func createGroup(name: String) async throws -> WTMGroup {
        guard let userID = client.auth.currentSession?.user.id else {
            throw APIError.notAuthenticated
        }
        struct NewGroup: Encodable {
            let name: String
            let createdBy: UUID
            enum CodingKeys: String, CodingKey {
                case name
                case createdBy = "created_by"
            }
        }
        // The `groups_add_creator_as_owner` trigger adds the caller as
        // `owner` in group_members once this insert lands.
        return try await client.from("groups")
            .insert(NewGroup(name: name, createdBy: userID))
            .single()
            .execute()
            .value
    }

    public func joinGroup(inviteCode: String) async throws -> WTMGroup {
        try await client
            .rpc("join_group_with_invite_code", params: ["code": inviteCode])
            .single()
            .execute()
            .value
    }

    public func members(of groupID: UUID) async throws -> [WTMUser] {
        struct MemberRow: Decodable {
            let profiles: WTMUser
        }
        let rows: [MemberRow] = try await client.from("group_members")
            .select("profiles(*)")
            .eq("group_id", value: groupID)
            .execute()
            .value
        return rows.map(\.profiles)
    }

    public func previewItinerary(inviteCode: String) async throws -> Itinerary? {
        // Row shape mirrors preview_itinerary_by_invite_code's RETURNS TABLE
        // in supabase/migrations/0001_init.sql. `timeSlot` is decoded as the
        // raw Postgres tstzrange text (e.g. `["2026-08-11 18:00:00+00","2026-08-11 19:00:00+00")`)
        // — parsing that into start/end Dates is left as a follow-up since
        // this preview path isn't part of the phase-1 UI flow yet.
        struct PreviewRow: Decodable {
            let itineraryID: UUID
            let itineraryStatus: ItineraryStatus
            let stopID: UUID
            let stopOrder: Int
            let venueName: String
            let venueCategory: String
            let venueRating: Double?

            enum CodingKeys: String, CodingKey {
                case itineraryID = "itinerary_id"
                case itineraryStatus = "itinerary_status"
                case stopID = "stop_id"
                case stopOrder = "stop_order"
                case venueName = "venue_name"
                case venueCategory = "venue_category"
                case venueRating = "venue_rating"
            }
        }

        let rows: [PreviewRow] = try await client
            .rpc("preview_itinerary_by_invite_code", params: ["code": inviteCode])
            .execute()
            .value

        guard let first = rows.first else { return nil }

        // venue.id / groupID aren't in the RPC's flattened output and aren't
        // needed for a read-only preview, so they're synthesized here rather
        // than plumbed through the function's return columns.
        let stops = rows.map { row in
            ItineraryStop(
                id: row.stopID,
                itineraryID: row.itineraryID,
                order: row.stopOrder,
                startTime: .now,
                endTime: .now,
                venue: Venue(
                    id: UUID(),
                    source: .googlePlaces,
                    externalID: "",
                    name: row.venueName,
                    category: row.venueCategory,
                    rating: row.venueRating
                )
            )
        }

        return Itinerary(id: first.itineraryID, groupID: UUID(), status: first.itineraryStatus, stops: stops)
    }
}
