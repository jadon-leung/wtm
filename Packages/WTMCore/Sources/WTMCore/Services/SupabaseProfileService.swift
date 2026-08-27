import Foundation
import Supabase

public struct SupabaseProfileService: ProfileServicing {
    private let client: SupabaseClient

    public init(client: SupabaseClient = SupabaseClientProvider.client) {
        self.client = client
    }

    public func fetch(userID: UUID) async throws -> WTMUser {
        try await client.from("profiles")
            .select()
            .eq("id", value: userID)
            .single()
            .execute()
            .value
    }

    public func update(_ user: WTMUser) async throws {
        try await client.from("profiles")
            .update(user)
            .eq("id", value: user.id)
            .execute()
    }
}
