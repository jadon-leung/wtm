import SwiftUI
import WTMCore

struct EmailSignInView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onSignedIn: (WTMUser) -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    private enum Field {
        case email, password
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.paper.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        modePicker

                        VStack(spacing: Theme.Spacing.sm) {
                            TextField("Email", text: $viewModel.email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .email)
                                .textFieldStyle(.wtmCard)

                            SecureField("Password", text: $viewModel.password)
                                .textContentType(viewModel.emailMode == .signUp ? .newPassword : .password)
                                .focused($focusedField, equals: .password)
                                .textFieldStyle(.wtmCard)
                        }

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }

                        Button {
                            Task {
                                if let user = await viewModel.submitEmail() {
                                    onSignedIn(user)
                                    dismiss()
                                }
                            }
                        } label: {
                            if viewModel.isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Text(viewModel.emailMode.rawValue)
                            }
                        }
                        .buttonStyle(.wtmPrimary)
                        .disabled(viewModel.isSubmitting)
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .navigationTitle("Continue with Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var modePicker: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(OnboardingViewModel.EmailMode.allCases) { mode in
                Button {
                    viewModel.emailMode = mode
                } label: {
                    Text(mode.rawValue)
                        .font(Theme.Typography.display(15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm + 2)
                        .foregroundStyle(viewModel.emailMode == mode ? .white : Theme.Colors.ink)
                        .background(viewModel.emailMode == mode ? Theme.Colors.coral : Theme.Colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                                .strokeBorder(viewModel.emailMode == mode ? Color.clear : Theme.Colors.hairline, lineWidth: 1.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
