import SwiftUI
import WTMCore

struct PhoneSignInView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onSignedIn: (WTMUser) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.paper.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            TextField("Phone number", text: $viewModel.phone)
                                .textContentType(.telephoneNumber)
                                .keyboardType(.phonePad)
                                .disabled(viewModel.otpSent)
                                .textFieldStyle(.wtmCard)

                            Text("Include your country code, e.g. +14155550123.")
                                .font(.footnote)
                                .foregroundStyle(Theme.Colors.mauve)
                        }

                        if viewModel.otpSent {
                            TextField("Verification code", text: $viewModel.otpCode)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.wtmCard)
                        }

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }

                        Button {
                            Task {
                                if viewModel.otpSent {
                                    if let user = await viewModel.verifyPhoneCode() {
                                        onSignedIn(user)
                                        dismiss()
                                    }
                                } else {
                                    await viewModel.requestPhoneCode()
                                }
                            }
                        } label: {
                            if viewModel.isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Text(viewModel.otpSent ? "Verify Code" : "Send Code")
                            }
                        }
                        .buttonStyle(.wtmPrimary)
                        .disabled(viewModel.isSubmitting)
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .navigationTitle("Continue with Phone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
