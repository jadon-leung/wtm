import Foundation
import Groups
import Home
import ItineraryPlanner
import Preferences
import Profile
import SwiftUI
import WTMCore

struct MainTabView: View {
    let currentUser: WTMUser
    let onSignOut: () -> Void

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeTab(
                currentUser: currentUser,
                onSeeAllGroups: { selectedTab = 1 },
                onOpenProfile: { selectedTab = 3 }
            )
            .tabItem { Label("Home", systemImage: "house") }
            .tag(0)

            GroupsTab(currentUser: currentUser)
                .tabItem { Label("Groups", systemImage: "person.3") }
                .tag(1)

            SoloItineraryView(currentUser: currentUser)
                .tabItem { Label("My Itinerary", systemImage: "wand.and.stars") }
                .tag(2)

            ProfileTab(currentUser: currentUser, onSignOut: onSignOut)
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(3)
        }
        #if DEBUG
        // Screenshot/QA hook, mirrors AppState's `--wtm-preview-*` launch
        // arguments — lets `xcrun simctl launch ... --wtm-preview-tab=profile`
        // land directly on a tab. Compiled out of Release builds.
        .task {
            let arguments = ProcessInfo.processInfo.arguments
            if arguments.contains("--wtm-preview-tab=profile") { selectedTab = 3 }
            if arguments.contains("--wtm-preview-tab=itinerary") { selectedTab = 2 }
        }
        #endif
    }
}

private enum HomeRoute: Hashable {
    case detail(WTMGroup)
    case itinerary(WTMGroup)
    case planner(WTMGroup)
}

private struct HomeTab: View {
    let currentUser: WTMUser
    let onSeeAllGroups: () -> Void
    let onOpenProfile: () -> Void

    @Environment(\.services) private var services
    @State private var path: [HomeRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                currentUser: currentUser,
                onPlanADay: startNewPlan,
                onSelectGroup: { group in path.append(.detail(group)) },
                onOpenPlan: { group in path.append(.itinerary(group)) },
                onSeeAllGroups: onSeeAllGroups,
                onOpenProfile: onOpenProfile
            )
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .detail(let group):
                    GroupDetailView(
                        group: group,
                        currentUser: currentUser,
                        onOpenItinerary: { group in path.append(.itinerary(group)) }
                    )
                case .itinerary(let group):
                    ItineraryView(group: group)
                case .planner(let group):
                    DayPlannerView(group: group)
                }
            }
        }
        #if DEBUG
        .task {
            if ProcessInfo.processInfo.arguments.contains("--wtm-preview-planner") { startNewPlan() }
        }
        #endif
    }

    private func startNewPlan() {
        Task {
            if let group = try? await services.groups.createGroup(name: autoPlanName()) {
                path.append(.planner(group))
            }
        }
    }
}

/// "Saturday afternoon", "Tuesday evening", etc. — a friendly default name
/// for a plan started straight from Home's "Plan a day" card, before the
/// group has any real identity of its own.
private func autoPlanName(from date: Date = .now) -> String {
    let weekday = date.formatted(.dateTime.weekday(.wide))
    let hour = Calendar.current.component(.hour, from: date)
    let partOfDay: String
    switch hour {
    case 0..<12: partOfDay = "morning"
    case 12..<17: partOfDay = "afternoon"
    default: partOfDay = "evening"
    }
    return "\(weekday) \(partOfDay)"
}

private enum GroupsRoute: Hashable {
    case detail(WTMGroup)
    case itinerary(WTMGroup)
}

private struct GroupsTab: View {
    let currentUser: WTMUser
    @State private var path: [GroupsRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            GroupsHomeView(onSelectGroup: { group in path.append(.detail(group)) })
                .navigationDestination(for: GroupsRoute.self) { route in
                    switch route {
                    case .detail(let group):
                        GroupDetailView(
                            group: group,
                            currentUser: currentUser,
                            onOpenItinerary: { group in path.append(.itinerary(group)) }
                        )
                    case .itinerary(let group):
                        ItineraryView(group: group)
                    }
                }
        }
    }
}

private struct ProfileTab: View {
    let currentUser: WTMUser
    let onSignOut: () -> Void
    @State private var showPreferencesSheet = false

    var body: some View {
        ProfileView(
            user: currentUser,
            onSignOut: onSignOut,
            onEditPreferences: { showPreferencesSheet = true }
        )
        .sheet(isPresented: $showPreferencesSheet) {
            PreferencesView(user: currentUser, onSaved: { showPreferencesSheet = false })
        }
    }
}
