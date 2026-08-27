import SwiftUI
import WTMCore

struct CreateGroupView: View {
    @Bindable var viewModel: GroupsViewModel
    let onCreated: (WTMGroup) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.paper.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            TextField("Group name", text: $name)
                                .textInputAutocapitalization(.words)
                                .textFieldStyle(.wtmCard)

                            Text("Everyone you invite will contribute their preferences before an itinerary is generated.")
                                .font(.footnote)
                                .foregroundStyle(Theme.Colors.mauve)
                        }

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }

                        Button {
                            Task {
                                isCreating = true
                                if let group = await viewModel.createGroup(name: name) {
                                    onCreated(group)
                                }
                                isCreating = false
                            }
                        } label: {
                            if isCreating {
                                ProgressView().tint(.white)
                            } else {
                                Text("Create Group")
                            }
                        }
                        .buttonStyle(.wtmPrimary)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
