import SwiftUI
import WTMCore

public struct ProfileView: View {
    private let user: WTMUser
    private let onSignOut: () -> Void
    private let onEditPreferences: () -> Void

    @Environment(\.services) private var services
    @State private var viewModel: ProfileViewModel?
    @State private var isSigningOut = false

    public init(user: WTMUser, onSignOut: @escaping () -> Void, onEditPreferences: @escaping () -> Void) {
        self.user = user
        self.onSignOut = onSignOut
        self.onEditPreferences = onEditPreferences
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.paper.ignoresSafeArea()

                if let viewModel {
                    content(for: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            if viewModel == nil {
                viewModel = ProfileViewModel(user: user, profileService: services.profile)
            }
        }
    }

    private func content(for viewModel: ProfileViewModel) -> some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                header(for: viewModel)

                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    EyebrowLabel("Your Info")

                    VStack(spacing: Theme.Spacing.sm) {
                        labeledField("Name", systemImage: "person.fill", text: Bindable(viewModel).displayName)
                            .textContentType(.name)
                        labeledField("Email", systemImage: "envelope.fill", text: Bindable(viewModel).email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        labeledField("Phone", systemImage: "phone.fill", text: Bindable(viewModel).phone)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                    }
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    EyebrowLabel("Preferences")

                    Button(action: onEditPreferences) {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundStyle(Theme.Colors.coral)
                                .frame(width: 20)
                            Text("Edit Preferences")
                                .font(Theme.Typography.display(16, weight: .semibold))
                                .foregroundStyle(Theme.Colors.ink)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote.bold())
                                .foregroundStyle(Theme.Colors.mauve)
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm + 4)
                        .wtmCard()
                    }
                    .buttonStyle(.plain)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button {
                    Task { await viewModel.save() }
                } label: {
                    if viewModel.isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text("Save Changes")
                    }
                }
                .buttonStyle(.wtmPrimary)
                .disabled(viewModel.isSaving)

                Button("Sign Out") {
                    Task {
                        isSigningOut = true
                        try? await services.auth.signOut()
                        isSigningOut = false
                        onSignOut()
                    }
                }
                .buttonStyle(.wtmDestructive)
                .disabled(isSigningOut)
            }
            .padding(Theme.Spacing.lg)
        }
    }

    private func header(for viewModel: ProfileViewModel) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            Circle()
                .fill(Theme.Colors.coralWash)
                .frame(width: 88, height: 88)
                .overlay(
                    Text(initials(for: viewModel.displayName))
                        .font(Theme.Typography.display(32, weight: .bold))
                        .foregroundStyle(Theme.Colors.coral)
                )

            Text(viewModel.displayName.isEmpty ? "Add your name" : viewModel.displayName)
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.Colors.ink)
        }
        .padding(.top, Theme.Spacing.md)
    }

    private func initials(for name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "?" }
        let parts = trimmed.split(separator: " ")
        let letters = parts.prefix(2).compactMap(\.first)
        return String(letters).uppercased()
    }

    private func labeledField(_ title: String, systemImage: String, text: Binding<String>) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: systemImage)
                .foregroundStyle(Theme.Colors.coral)
                .frame(width: 20)
            TextField(title, text: text)
                .font(Theme.Typography.display(16, weight: .medium))
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm + 4)
        .background(Theme.Colors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                .strokeBorder(Theme.Colors.hairline, lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
        .foregroundStyle(Theme.Colors.ink)
    }
}

#Preview {
    ProfileView(
        user: WTMUser(id: UUID(), displayName: "Jordan Lee", email: "jordan@example.com"),
        onSignOut: {},
        onEditPreferences: {}
    )
    .environment(\.services, .mock)
}
