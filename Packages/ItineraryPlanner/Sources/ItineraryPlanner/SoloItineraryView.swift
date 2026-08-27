import SwiftUI
import WTMCore

/// A personal itinerary generated from just your own preferences, with no
/// group involved. Reuses the existing group-based itinerary machinery
/// under the hood — every itinerary in the data model hangs off a group
/// (see supabase/migrations/0001_init.sql), so "just for me" is modeled as
/// a single-member group named "My Itinerary" that's created on first use
/// and reused after that, rather than as a parallel, groupless code path.
public struct SoloItineraryView: View {
    private let currentUser: WTMUser

    @Environment(\.services) private var services
    @State private var resolvedGroup: WTMGroup?
    @State private var errorMessage: String?

    public init(currentUser: WTMUser) {
        self.currentUser = currentUser
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.paper.ignoresSafeArea()

                if let resolvedGroup {
                    ItineraryView(
                        group: resolvedGroup,
                        emptyStateDescription: "Generate a personalized itinerary from your own preferences."
                    )
                } else if let errorMessage {
                    VStack(spacing: Theme.Spacing.md) {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                        Button("Retry") {
                            Task { await resolveGroup() }
                        }
                        .buttonStyle(.wtmSecondary)
                    }
                    .padding(Theme.Spacing.lg)
                } else {
                    ProgressView()
                }
            }
        }
        .task {
            if resolvedGroup == nil {
                await resolveGroup()
            }
        }
    }

    private func resolveGroup() async {
        errorMessage = nil
        do {
            resolvedGroup = try await services.groups.resolvePersonalGroup()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private let personalGroupName = "My Itinerary"

extension GroupServicing {
    fileprivate func resolvePersonalGroup() async throws -> WTMGroup {
        let groups = try await myGroups()
        if let existing = groups.first(where: { $0.name == personalGroupName }) {
            return existing
        }
        return try await createGroup(name: personalGroupName)
    }
}

#Preview {
    SoloItineraryView(currentUser: WTMUser(id: UUID(), displayName: "Jordan"))
        .environment(\.services, .mock)
}
