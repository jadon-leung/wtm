import Foundation
import SwiftUI

/// Bundles every service protocol conformance the app needs. Feature
/// packages read this via `@Environment(\.services)` rather than each
/// constructing their own Supabase-backed service, so previews/tests can
/// swap in `.mock` without touching feature code.
public struct ServiceContainer: Sendable {
    public var auth: any AuthServicing
    public var preferences: any PreferencesServicing
    public var groups: any GroupServicing
    public var itinerary: any ItineraryServicing
    public var profile: any ProfileServicing

    public init(
        auth: any AuthServicing,
        preferences: any PreferencesServicing,
        groups: any GroupServicing,
        itinerary: any ItineraryServicing,
        profile: any ProfileServicing
    ) {
        self.auth = auth
        self.preferences = preferences
        self.groups = groups
        self.itinerary = itinerary
        self.profile = profile
    }

    /// Real, Supabase-backed services (itinerary excepted — there's no
    /// engine to call yet, so it stays mocked even in the "live" container).
    public static let live = ServiceContainer(
        auth: SupabaseAuthService(),
        preferences: SupabasePreferencesService(),
        groups: SupabaseGroupService(),
        itinerary: MockItineraryService(),
        profile: SupabaseProfileService()
    )

    public static let mock = ServiceContainer(
        auth: MockAuthService(),
        preferences: MockPreferencesService(),
        groups: MockGroupService(),
        itinerary: MockItineraryService(),
        profile: MockProfileService()
    )
}

private struct ServiceContainerKey: EnvironmentKey {
    // `.mock` so previews/tests that forget to inject `\.services` don't
    // crash reading Supabase config from a bundle that was never set up
    // with SUPABASE_URL/SUPABASE_ANON_KEY.
    static let defaultValue = ServiceContainer.mock
}

extension EnvironmentValues {
    public var services: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}
