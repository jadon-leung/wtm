import Supabase

/// Single shared `SupabaseClient` instance for the app. `SupabaseClient` is
/// itself `Sendable` and safe to share, so this just avoids constructing it
/// (and re-reading Info.plist) more than once.
public enum SupabaseClientProvider {
    public static let client: SupabaseClient = SupabaseClient(
        supabaseURL: SupabaseConfig.url,
        supabaseKey: SupabaseConfig.anonKey
    )
}
