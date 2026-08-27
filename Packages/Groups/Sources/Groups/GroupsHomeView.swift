import SwiftUI
import WTMCore

public struct GroupsHomeView: View {
    private let onSelectGroup: (WTMGroup) -> Void

    @Environment(\.services) private var services
    @State private var viewModel: GroupsViewModel?
    @State private var showCreateSheet = false
    @State private var showJoinSheet = false

    public init(onSelectGroup: @escaping (WTMGroup) -> Void) {
        self.onSelectGroup = onSelectGroup
    }

    public var body: some View {
        ZStack {
            Theme.Colors.paper.ignoresSafeArea()

            if let viewModel {
                content(for: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Groups")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Label("Create Group", systemImage: "plus")
                    }
                    Button {
                        showJoinSheet = true
                    } label: {
                        Label("Join with Code", systemImage: "person.badge.plus")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.Colors.coral)
                }
            }
        }
        .task {
            if viewModel == nil {
                let model = GroupsViewModel(groupService: services.groups)
                viewModel = model
                await model.loadGroups()
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            if let viewModel {
                CreateGroupView(viewModel: viewModel, onCreated: { group in
                    showCreateSheet = false
                    onSelectGroup(group)
                })
            }
        }
        .sheet(isPresented: $showJoinSheet) {
            if let viewModel {
                JoinGroupView(viewModel: viewModel, onJoined: { group in
                    showJoinSheet = false
                    onSelectGroup(group)
                })
            }
        }
    }

    @ViewBuilder
    private func content(for viewModel: GroupsViewModel) -> some View {
        if viewModel.groups.isEmpty && !viewModel.isLoading {
            ContentUnavailableView(
                "No Groups Yet",
                systemImage: "person.3",
                description: Text("Create a group or join one with an invite code to start planning.")
            )
        } else {
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.sm) {
                    ForEach(viewModel.groups) { group in
                        GroupRow(group: group) { onSelectGroup(group) }
                    }
                }
                .padding(Theme.Spacing.lg)
            }
            .refreshable { await viewModel.loadGroups() }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
    }
}

private struct GroupRow: View {
    let group: WTMGroup
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                Circle()
                    .fill(Theme.Colors.coralWash)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(group.name.prefix(1)).uppercased())
                            .font(Theme.Typography.display(18, weight: .bold))
                            .foregroundStyle(Theme.Colors.coral)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.ink)
                    StatusBadge(status: group.status)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.bold())
                    .foregroundStyle(Theme.Colors.mauve)
            }
            .padding(Theme.Spacing.md)
            .wtmCard()
        }
        .buttonStyle(.plain)
    }
}

private struct StatusBadge: View {
    let status: GroupStatus

    private var tint: Color {
        switch status {
        case .forming: Theme.Colors.gold
        case .active: Theme.Colors.sage
        case .completed: Theme.Colors.mauve
        case .archived: Theme.Colors.mauve
        }
    }

    var body: some View {
        Text(status.rawValue.capitalized)
            .font(Theme.Typography.display(12, weight: .semibold))
            .foregroundStyle(tint)
    }
}

#Preview {
    NavigationStack {
        GroupsHomeView(onSelectGroup: { _ in })
            .environment(\.services, .mock)
    }
}
