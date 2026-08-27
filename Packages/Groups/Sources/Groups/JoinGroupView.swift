import SwiftUI
import WTMCore

struct JoinGroupView: View {
    @Bindable var viewModel: GroupsViewModel
    let onJoined: (WTMGroup) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var inviteCode = ""
    @State private var isJoining = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.paper.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        TextField("Invite code", text: $inviteCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .textFieldStyle(.wtmCard)

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }

                        Button {
                            Task {
                                isJoining = true
                                if let group = await viewModel.joinGroup(inviteCode: inviteCode) {
                                    onJoined(group)
                                }
                                isJoining = false
                            }
                        } label: {
                            if isJoining {
                                ProgressView().tint(.white)
                            } else {
                                Text("Join Group")
                            }
                        }
                        .buttonStyle(.wtmPrimary)
                        .disabled(inviteCode.trimmingCharacters(in: .whitespaces).isEmpty || isJoining)
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .navigationTitle("Join Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
