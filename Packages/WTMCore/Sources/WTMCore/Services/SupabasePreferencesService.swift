import Foundation
import Supabase

public struct SupabasePreferencesService: PreferencesServicing {
    private let client: SupabaseClient

    public init(client: SupabaseClient = SupabaseClientProvider.client) {
        self.client = client
    }

    public func fetch(userID: UUID) async throws -> UserPreferences? {
        let rows: [UserPreferences] = try await client.from("preferences")
            .select()
            .eq("user_id", value: userID)
            .execute()
            .value
        return rows.first
    }

    public func save(_ preferences: UserPreferences) async throws {
        try await client.from("preferences")
            .upsert(preferences, onConflict: "user_id")
            .execute()
    }
}
