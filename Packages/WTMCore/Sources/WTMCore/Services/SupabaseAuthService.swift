import Foundation
import Supabase

/// Assumes email confirmation is turned off in Supabase Auth settings for
/// phase 1 (Authentication -> Providers -> Email -> "Confirm email"). If you
/// turn it on, `signUpWithEmail` needs to handle the no-session-yet case
/// (show a "check your email" screen instead of treating signup as sign-in).
public struct SupabaseAuthService: AuthServicing {
    private let client: SupabaseClient

    public init(client: SupabaseClient = SupabaseClientProvider.client) {
        self.client = client
    }

    public func currentUser() async -> WTMUser? {
        guard let session = try? await client.auth.session else { return nil }
        return try? await profile(for: session.user.id, email: session.user.email)
    }

    public func signInWithApple(identityToken: String, nonce: String, fullName: String?) async throws -> WTMUser {
        let session = try await client.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(provider: .apple, idToken: identityToken, nonce: nonce)
        )
        return try await upsertProfile(
            id: session.user.id,
            displayName: fullName,
            email: session.user.email
        )
    }

    public func signInWithEmail(email: String, password: String) async throws -> WTMUser {
        let session = try await client.auth.signIn(email: email, password: password)
        return try await profile(for: session.user.id, email: session.user.email)
    }

    public func signUpWithEmail(email: String, password: String) async throws -> WTMUser {
        let response = try await client.auth.signUp(email: email, password: password)
        return try await upsertProfile(id: response.user.id, displayName: nil, email: email)
    }

    public func requestPhoneCode(phone: String) async throws {
        try await client.auth.signInWithOTP(phone: phone)
    }

    public func verifyPhoneCode(phone: String, code: String) async throws -> WTMUser {
        let response = try await client.auth.verifyOTP(phone: phone, token: code, type: .sms)
        return try await upsertProfile(id: response.user.id, displayName: nil, phone: phone)
    }

    public func continueAsGuest() async throws -> WTMUser {
        let session = try await client.auth.signInAnonymously()
        return try await upsertProfile(id: session.user.id, displayName: nil, isGuest: true)
    }

    public func signOut() async throws {
        try await client.auth.signOut()
    }

    // MARK: - profiles table

    private func profile(for id: UUID, email: String?) async throws -> WTMUser {
        do {
            return try await client.from("profiles")
                .select()
                .eq("id", value: id)
                .single()
                .execute()
                .value
        } catch {
            // No profile row yet (e.g. first sign-in right after the
            // auth.users row was created) — create one on the fly.
            return try await upsertProfile(id: id, displayName: nil, email: email)
        }
    }

    private func upsertProfile(
        id: UUID,
        displayName: String?,
        email: String? = nil,
        phone: String? = nil,
        isGuest: Bool = false
    ) async throws -> WTMUser {
        let user = WTMUser(id: id, displayName: displayName, phone: phone, email: email, isGuest: isGuest)
        return try await client.from("profiles")
            .upsert(user, onConflict: "id")
            .single()
            .execute()
            .value
    }
}
