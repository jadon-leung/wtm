import Foundation

public protocol AuthServicing: Sendable {
    /// Nil if there's no signed-in session.
    func currentUser() async -> WTMUser?

    func signInWithApple(identityToken: String, nonce: String, fullName: String?) async throws -> WTMUser
    func signInWithEmail(email: String, password: String) async throws -> WTMUser
    func signUpWithEmail(email: String, password: String) async throws -> WTMUser
    func requestPhoneCode(phone: String) async throws
    func verifyPhoneCode(phone: String, code: String) async throws -> WTMUser

    /// Anonymous session for the "preview before you sign up" guest flow.
    func continueAsGuest() async throws -> WTMUser

    func signOut() async throws
}
