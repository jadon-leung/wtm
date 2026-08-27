import SwiftUI
import WTMCore

/// The app's landing tab: a "what's next" dashboard rather than a list of
/// groups — surfaces the next scheduled plan, a quick way to start a new
/// one, and a look back at past days out, all sourced from the same
/// group/itinerary services the Groups and Itinerary tabs use.
public struct HomeView: View {
    private let currentUser: WTMUser
    private let onPlanADay: () -> Void
    private let onSelectGroup: (WTMGroup) -> Void
    private let onOpenPlan: (WTMGroup) -> Void
    private let onSeeAllGroups: () -> Void
    private let onOpenProfile: () -> Void

    @Environment(\.services) private var services
    @State private var viewModel: HomeViewModel?

    public init(
        currentUser: WTMUser,
        onPlanADay: @escaping () -> Void,
        onSelectGroup: @escaping (WTMGroup) -> Void,
        onOpenPlan: @escaping (WTMGroup) -> Void,
        onSeeAllGroups: @escaping () -> Void,
        onOpenProfile: @escaping () -> Void
    ) {
        self.currentUser = currentUser
        self.onPlanADay = onPlanADay
        self.onSelectGroup = onSelectGroup
        self.onOpenPlan = onOpenPlan
        self.onSeeAllGroups = onSeeAllGroups
        self.onOpenProfile = onOpenProfile
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
        .navigationTitle("Home")
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if viewModel == nil {
                let model = HomeViewModel(
                    currentUserID: currentUser.id,
                    groupService: services.groups,
                    itineraryService: services.itinerary
                )
                viewModel = model
                await model.load()
            }
        }
    }

    private func content(for viewModel: HomeViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                header
                heroCard

                if let nextUp = viewModel.nextUp {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        EyebrowLabel("Next Up")
                        NextUpCard(plan: nextUp, action: { onOpenPlan(nextUp.group) })
                    }
                }

                if !viewModel.groups.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        HStack {
                            EyebrowLabel("Your Groups")
                            Spacer()
                            Button(action: onSeeAllGroups) {
                                Text("See all")
                                    .font(Theme.Typography.display(14, weight: .semibold))
                                    .foregroundStyle(Theme.Colors.coral)
                            }
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Theme.Spacing.md) {
                                ForEach(viewModel.groups) { group in
                                    GroupAvatar(group: group, action: { onSelectGroup(group) })
                                }
                            }
                        }
                    }
                } else if !viewModel.isLoading {
                    Text("Create a group to start planning your first day out.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.mauve)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, Theme.Spacing.lg)
                }

                if !viewModel.pastPlans.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        EyebrowLabel("Past Plans")
                        PastPlansCard(plans: viewModel.pastPlans, action: onOpenPlan)
                    }
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .refreshable { await viewModel.load() }
        .overlay {
            if viewModel.isLoading && viewModel.groups.isEmpty {
                ProgressView()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Welcome back,")
                    .font(Theme.Typography.display(15, weight: .medium))
                    .foregroundStyle(Theme.Colors.mauve)
                Text(firstName)
                    .font(Theme.Typography.hero)
                    .foregroundStyle(Theme.Colors.ink)
            }

            Spacer()

            Button(action: onOpenProfile) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Theme.Colors.surface))
                    .overlay(Circle().strokeBorder(Theme.Colors.hairline, lineWidth: 1))
            }
        }
        .padding(.top, Theme.Spacing.sm)
    }

    private var firstName: String {
        guard let displayName = currentUser.displayName, !displayName.isEmpty else { return "there" }
        return displayName.split(separator: " ").first.map(String.init) ?? displayName
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Plan a day")
                        .font(Theme.Typography.display(28, weight: .heavy))
                        .foregroundStyle(.white)
                    Text("Pick a group and let WTM put the day together.")
                        .font(Theme.Typography.display(15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()

                RouteGlyph()
            }

            Button(action: onPlanADay) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.Colors.coral)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(.white))
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.coral)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }
}

/// Decorative stand-in for a route line on the hero card — three stops
/// joined by a thread, echoing the itinerary-stop visual language used
/// elsewhere without pulling in real stop data here.
private struct RouteGlyph: View {
    var body: some View {
        VStack(spacing: 6) {
            Circle().frame(width: 8, height: 8)
            Rectangle().frame(width: 1.5, height: 18)
            Circle().frame(width: 8, height: 8)
            Rectangle().frame(width: 1.5, height: 18)
            Circle().frame(width: 8, height: 8)
        }
        .foregroundStyle(.white.opacity(0.5))
        .padding(.top, 6)
    }
}

private struct NextUpCard: View {
    let plan: HomeViewModel.UpcomingPlan
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack(alignment: .top) {
                    Text(plan.group.name)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.ink)

                    Spacer()

                    if let timeText {
                        Text(timeText)
                            .font(Theme.Typography.display(13, weight: .bold))
                            .foregroundStyle(Theme.Colors.coral)
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, 4)
                            .background(Theme.Colors.coralWash)
                            .clipShape(Capsule())
                    }
                }

                Text([stopsText, durationText].compactMap { $0 }.joined(separator: " · "))
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.mauve)

                if !plan.companionNames.isEmpty {
                    Text("with \(plan.companionNames.joined(separator: ", "))")
                        .font(Theme.Typography.display(15, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink)
                }
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .wtmCard()
        }
        .buttonStyle(.plain)
    }

    private var timeText: String? {
        plan.itinerary.stops.first?.startTime.formatted(date: .omitted, time: .shortened)
    }

    private var stopsText: String {
        let count = plan.itinerary.stops.count
        return count == 1 ? "1 stop" : "\(count) stops"
    }

    private var durationText: String? {
        guard
            let start = plan.itinerary.stops.first?.startTime,
            let end = plan.itinerary.stops.last?.endTime
        else { return nil }

        let minutes = max(0, Int(end.timeIntervalSince(start) / 60))
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours == 0 { return "\(remainder) min" }
        if remainder == 0 { return "\(hours) hr" }
        return "\(hours) hr \(remainder) min"
    }
}

private struct GroupAvatar: View {
    let group: WTMGroup
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.xs) {
                Circle()
                    .fill(Theme.Colors.coralWash)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(initials)
                            .font(Theme.Typography.display(18, weight: .bold))
                            .foregroundStyle(Theme.Colors.coral)
                    )

                Text(group.name)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.ink)
                    .lineLimit(1)
                    .frame(width: 68)
            }
        }
        .buttonStyle(.plain)
    }

    private var initials: String {
        let letters = group.name.split(separator: " ").prefix(2).compactMap(\.first)
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }
}

private struct PastPlansCard: View {
    let plans: [HomeViewModel.PastPlan]
    let action: (WTMGroup) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(plans.enumerated()), id: \.element.id) { index, plan in
                if index > 0 {
                    Divider().padding(.leading, Theme.Spacing.md)
                }

                Button(action: { action(plan.group) }) {
                    HStack(spacing: Theme.Spacing.md) {
                        Text(plan.group.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                            .font(Theme.Typography.display(14, weight: .bold))
                            .foregroundStyle(Theme.Colors.coral)
                            .frame(width: 52, alignment: .leading)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(plan.group.name)
                                .font(Theme.Typography.display(16, weight: .bold))
                                .foregroundStyle(Theme.Colors.ink)

                            if let stopCount = plan.itinerary?.stops.count, stopCount > 0 {
                                Text(stopCount == 1 ? "1 stop" : "\(stopCount) stops")
                                    .font(.footnote)
                                    .foregroundStyle(Theme.Colors.mauve)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.footnote.bold())
                            .foregroundStyle(Theme.Colors.mauve)
                    }
                    .padding(Theme.Spacing.md)
                }
                .buttonStyle(.plain)
            }
        }
        .wtmCard()
    }
}

#Preview {
    NavigationStack {
        HomeView(
            currentUser: WTMUser(id: UUID(), displayName: "Jordan Lee"),
            onPlanADay: {},
            onSelectGroup: { _ in },
            onOpenPlan: { _ in },
            onSeeAllGroups: {},
            onOpenProfile: {}
        )
        .environment(\.services, .mock)
    }
}
