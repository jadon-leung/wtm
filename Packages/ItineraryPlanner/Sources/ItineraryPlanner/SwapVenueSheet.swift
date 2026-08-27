import SwiftUI
import WTMCore

struct SwapVenueSheet: View {
    let stop: ItineraryStop
    let onSelect: (VenueAlternate) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.paper.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.sm) {
                        ForEach(stop.alternates.sorted(by: { $0.rank < $1.rank })) { alternate in
                            Button {
                                onSelect(alternate)
                            } label: {
                                HStack(spacing: Theme.Spacing.md) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(alternate.venue.name)
                                            .font(Theme.Typography.display(17, weight: .bold))
                                            .foregroundStyle(Theme.Colors.ink)
                                        Text(alternate.venue.category)
                                            .font(Theme.Typography.display(13, weight: .medium))
                                            .foregroundStyle(Theme.Colors.mauve)
                                    }
                                    Spacer()
                                    if let rating = alternate.venue.rating {
                                        Label(String(format: "%.1f", rating), systemImage: "star.fill")
                                            .font(Theme.Typography.display(13, weight: .bold))
                                            .foregroundStyle(Theme.Colors.gold)
                                    }
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .foregroundStyle(Theme.Colors.coral)
                                }
                                .padding(Theme.Spacing.md)
                                .wtmCard()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .navigationTitle("Swap \(stop.venue.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
