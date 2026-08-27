import SwiftUI
import WTMCore

public struct GroupDetailView: View {
    private let group: WTMGroup
    private let currentUser: WTMUser
    private let onOpenItinerary: (WTMGroup) -> Void

    @Environment(\.services) private var services
    @State private var viewModel: GroupDetailViewModel?

    public init(group: WTMGroup, currentUser: WTMUser, onOpenItinerary: @escaping (WTMGroup) -> Void) {
        self.group = group
        self.currentUser = currentUser
        self.onOpenItinerary = onOpenItinerary
    }

    public var body: some View {
        ZStack {
            Theme.Colors.paper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    inviteCard

                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        EyebrowLabel("Members")
                        membersCard
                    }

                    Button {
                        onOpenItinerary(group)
                    } label: {
                        Label("View Itinerary", systemImage: "map.fill")
                    }
                    .buttonStyle(.wtmPrimary)
                }
                .padding(Theme.Spacing.lg)
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil {
                let model = GroupDetailViewModel(group: group, groupService: services.groups)
                viewModel = model
                await model.loadMembers()
            }
        }
    }

    private var inviteCard: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    EyebrowLabel("Invite Code")
                    Text(group.inviteCode)
                        .font(Theme.Typography.mono(24, weight: .bold))
                        .tracking(3)
                        .foregroundStyle(Theme.Colors.ink)
                }
                Spacer()
                ShareLink(item: "Join my WTM group \"\(group.name)\" with code \(group.inviteCode)") {
                    Image(systemName: "square.and.arrow.up.circle.fill")
                        .font(.title)
                        .foregroundStyle(Theme.Colors.coral)
                }
            }
            .padding(Theme.Spacing.md)

            TicketNotchDivider()

            Text("Share this code so friends can join before the itinerary is generated.")
                .font(.footnote)
                .foregroundStyle(Theme.Colors.mauve)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.md)
        }
        .wtmCard()
    }

    private var membersCard: some View {
        VStack(spacing: 0) {
            if let viewModel {
                if viewModel.members.isEmpty && viewModel.isLoading {
                    ProgressView()
                        .padding(Theme.Spacing.md)
                } else {
                    ForEach(Array(viewModel.members.enumerated()), id: \.element.id) { index, member in
                        if index > 0 {
                            Divider().padding(.leading, Theme.Spacing.md + 36 + Theme.Spacing.sm)
                        }
                        MemberRow(member: member)
                    }
                }
            }
        }
        .wtmCard()
    }
}

private struct MemberRow: View {
    let member: WTMUser

    private var displayName: String {
        member.displayName ?? member.email ?? member.phone ?? "Member"
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Circle()
                .fill(Theme.Colors.coralWash)
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(displayName.prefix(1)).uppercased())
                        .font(Theme.Typography.display(14, weight: .bold))
                        .foregroundStyle(Theme.Colors.coral)
                )
            Text(displayName)
                .font(Theme.Typography.display(15, weight: .medium))
                .foregroundStyle(Theme.Colors.ink)
            Spacer()
        }
        .padding(Theme.Spacing.md)
    }
}

#Preview {
    NavigationStack {
        GroupDetailView(
            group: WTMGroup(id: UUID(), name: "Friday Crew", createdBy: UUID(), inviteCode: "AB12CD"),
            currentUser: WTMUser(id: UUID(), displayName: "Jordan"),
            onOpenItinerary: { _ in }
        )
        .environment(\.services, .mock)
    }
}
