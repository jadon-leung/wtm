import Foundation
import Observation
import WTMCore

@MainActor
@Observable
public final class OnboardingViewModel {
    public enum EmailMode: String, CaseIterable, Identifiable {
        case signIn = "Sign In"
        case signUp = "Sign Up"
        public var id: Self { self }
    }

    public enum Field {
        case appleButton
        case email
        case phone
    }

    public var activeField: Field?

    public var emailMode: EmailMode = .signIn
    public var email = ""
    public var password = ""

    public var phone = ""
    public var otpCode = ""
    public var otpSent = false

    public var isSubmitting = false
    public var errorMessage: String?

    private let authService: any AuthServicing

    public init(authService: any AuthServicing) {
        self.authService = authService
    }

    public func signInWithApple(identityToken: String, nonce: String, fullName: String?) async -> WTMUser? {
        await run {
            try await self.authService.signInWithApple(identityToken: identityToken, nonce: nonce, fullName: fullName)
        }
    }

    public func submitEmail() async -> WTMUser? {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Enter an email and password."
            return nil
        }
        return await run {
            switch self.emailMode {
            case .signIn:
                try await self.authService.signInWithEmail(email: self.email, password: self.password)
            case .signUp:
                try await self.authService.signUpWithEmail(email: self.email, password: self.password)
            }
        }
    }

    public func requestPhoneCode() async {
        guard !phone.isEmpty else {
            errorMessage = "Enter a phone number."
            return
        }
        _ = await run {
            try await self.authService.requestPhoneCode(phone: self.phone)
            self.otpSent = true
            return nil as WTMUser?
        }
    }

    public func verifyPhoneCode() async -> WTMUser? {
        guard !otpCode.isEmpty else {
            errorMessage = "Enter the code we texted you."
            return nil
        }
        return await run {
            try await self.authService.verifyPhoneCode(phone: self.phone, code: self.otpCode)
        }
    }

    private func run(_ operation: @escaping () async throws -> WTMUser?) async -> WTMUser? {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            return try await operation()
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
