import AuthenticationServices
import SwiftUI
import WTMCore

public struct SignInView: View {
    private let onSignedIn: (WTMUser) -> Void
    #if DEBUG
    private let onDebugSkipToPreferences: () -> Void
    private let onDebugSkipToMainApp: () -> Void
    #endif

    @Environment(\.services) private var services
    @State private var viewModel: OnboardingViewModel?
    @State private var currentNonce = AppleNonce.randomString()
    @State private var showEmailSheet = false
    @State private var showPhoneSheet = false

    #if DEBUG
    public init(
        onSignedIn: @escaping (WTMUser) -> Void,
        onDebugSkipToPreferences: @escaping () -> Void,
        onDebugSkipToMainApp: @escaping () -> Void
    ) {
        self.onSignedIn = onSignedIn
        self.onDebugSkipToPreferences = onDebugSkipToPreferences
        self.onDebugSkipToMainApp = onDebugSkipToMainApp
    }
    #else
    public init(onSignedIn: @escaping (WTMUser) -> Void) {
        self.onSignedIn = onSignedIn
    }
    #endif

    public var body: some View {
        ZStack {
            Theme.Colors.paper.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                Spacer()

                VStack(spacing: Theme.Spacing.sm) {
                    HStack(spacing: 2) {
                        Text("WTM")
                            .font(Theme.Typography.hero)
                            .foregroundStyle(Theme.Colors.ink)
                        Circle()
                            .fill(Theme.Colors.coral)
                            .frame(width: 10, height: 10)
                            .offset(y: -12)
                    }
                    Text("Plan hangouts your whole group actually agrees on.")
                        .font(Theme.Typography.display(15, weight: .medium))
                        .foregroundStyle(Theme.Colors.mauve)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, Theme.Spacing.xl)

                Spacer()

                VStack(spacing: Theme.Spacing.md) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = AppleNonce.sha256(currentNonce)
                    } onCompletion: { result in
                        handleAppleCompletion(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))

                    Button("Continue with Email") { showEmailSheet = true }
                        .buttonStyle(.wtmPrimary)

                    Button("Continue with Phone") { showPhoneSheet = true }
                        .buttonStyle(.wtmSecondary)

                    #if DEBUG
                    debugSection
                    #endif
                }
                .padding(.horizontal, Theme.Spacing.lg)

                if let errorMessage = viewModel?.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal, Theme.Spacing.lg)
                }

                Spacer()
            }
        }
        .task {
            if viewModel == nil {
                viewModel = OnboardingViewModel(authService: services.auth)
            }
        }
        .sheet(isPresented: $showEmailSheet) {
            if let viewModel {
                EmailSignInView(viewModel: viewModel, onSignedIn: onSignedIn)
            }
        }
        .sheet(isPresented: $showPhoneSheet) {
            if let viewModel {
                PhoneSignInView(viewModel: viewModel, onSignedIn: onSignedIn)
            }
        }
    }

    #if DEBUG
    private var debugSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack {
                VStack { Divider() }
                Text("DEBUG")
                    .font(Theme.Typography.eyebrow)
                    .tracking(1.2)
                    .foregroundStyle(Theme.Colors.mauve)
                VStack { Divider() }
            }
            .padding(.top, Theme.Spacing.xs)

            Button("Skip to Preferences", action: onDebugSkipToPreferences)
                .buttonStyle(.wtmSecondary)

            Button("Skip to Main App", action: onDebugSkipToMainApp)
                .buttonStyle(.wtmSecondary)
        }
    }
    #endif

    private func handleAppleCompletion(_ result: Result<ASAuthorization, any Error>) {
        switch result {
        case .failure(let error):
            viewModel?.errorMessage = error.localizedDescription

        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let identityToken = String(data: tokenData, encoding: .utf8)
            else {
                viewModel?.errorMessage = "Apple didn't return a valid credential."
                return
            }

            let fullName = credential.fullName?.formatted()
            let nonce = currentNonce
            // A fresh request needs a fresh nonce next time the button is used.
            currentNonce = AppleNonce.randomString()

            Task {
                if let user = await viewModel?.signInWithApple(
                    identityToken: identityToken,
                    nonce: nonce,
                    fullName: (fullName?.isEmpty ?? true) ? nil : fullName
                ) {
                    onSignedIn(user)
                }
            }
        }
    }
}

#Preview {
    #if DEBUG
    SignInView(onSignedIn: { _ in }, onDebugSkipToPreferences: {}, onDebugSkipToMainApp: {})
        .environment(\.services, .mock)
    #else
    SignInView(onSignedIn: { _ in })
        .environment(\.services, .mock)
    #endif
}
