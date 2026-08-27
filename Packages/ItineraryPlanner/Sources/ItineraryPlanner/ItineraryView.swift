import SwiftUI
import WTMCore

public struct ItineraryView: View {
    private let group: WTMGroup
    private let emptyStateDescription: String

    @Environment(\.services) private var services
    @State private var viewModel: ItineraryViewModel?
    @State private var swappingStop: ItineraryStop?

    public init(
        group: WTMGroup,
        emptyStateDescription: String = "Generate one once everyone's added their preferences."
    ) {
        self.group = group
        self.emptyStateDescription = emptyStateDescription
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
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil {
                let model = ItineraryViewModel(group: group, itineraryService: services.itinerary)
                viewModel = model
                await model.load()
            }
        }
        .sheet(item: $swappingStop) { stop in
            SwapVenueSheet(stop: stop) { alternate in
                swappingStop = nil
                Task { await viewModel?.swap(stop: stop, forAlternate: alternate) }
            }
        }
    }

    @ViewBuilder
    private func content(for viewModel: ItineraryViewModel) -> some View {
        if let itinerary = viewModel.itinerary, !itinerary.stops.isEmpty {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text("Today's Itinerary")
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.Colors.ink)
                        .padding(.horizontal, Theme.Spacing.xs)

                    ForEach(
                        Array(itinerary.stops.sorted(by: { $0.order < $1.order }).enumerated()),
                        id: \.element.id
                    ) { index, stop in
                        ItineraryStopCard(
                            stopNumber: index + 1,
                            stop: stop,
                            onSwap: { swappingStop = stop },
                            onFeedback: { action in
                                Task { await viewModel.submitFeedback(stop: stop, action: action) }
                            }
                        )
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .refreshable { await viewModel.load() }
        } else if viewModel.isGenerating || viewModel.isLoading {
            VStack(spacing: Theme.Spacing.md) {
                ProgressView().tint(Theme.Colors.coral)
                Text(viewModel.isGenerating ? "Building your itinerary…" : "Loading…")
                    .font(Theme.Typography.display(15, weight: .medium))
                    .foregroundStyle(Theme.Colors.mauve)
            }
        } else {
            VStack(spacing: Theme.Spacing.lg) {
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.Colors.coral)
                    Text("No Itinerary Yet")
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.Colors.ink)
                    Text(emptyStateDescription)
                        .font(Theme.Typography.display(14, weight: .medium))
                        .foregroundStyle(Theme.Colors.mauve)
                        .multilineTextAlignment(.center)
                }

                Button("Generate Itinerary") {
                    Task { await viewModel.generate() }
                }
                .buttonStyle(.wtmPrimary)
                .padding(.horizontal, Theme.Spacing.lg)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .padding(Theme.Spacing.xl)
        }
    }
}

#Preview {
    NavigationStack {
        ItineraryView(group: WTMGroup(id: UUID(), name: "Friday Crew", createdBy: UUID(), inviteCode: "AB12CD"))
            .environment(\.services, .mock)
    }
}
