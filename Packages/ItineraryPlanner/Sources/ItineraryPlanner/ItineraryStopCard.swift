import SwiftUI
import WTMCore

/// A stop rendered as a ticket stub: pass details up top, a perforated tear
/// line, then an "admit one" action row below — because a hangout
/// itinerary really is just a sequence of passes for the day.
struct ItineraryStopCard: View {
    let stopNumber: Int
    let stop: ItineraryStop
    let onSwap: () -> Void
    let onFeedback: (FeedbackAction) -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Text("STOP \(String(format: "%02d", stopNumber))")
                        .font(Theme.Typography.eyebrow)
                        .tracking(1.2)
                        .foregroundStyle(Theme.Colors.mauve)
                    Spacer()
                    if let rating = stop.venue.rating {
                        Label(String(format: "%.1f", rating), systemImage: "star.fill")
                            .font(Theme.Typography.display(13, weight: .bold))
                            .foregroundStyle(Theme.Colors.gold)
                    }
                }

                Text(timeRange)
                    .font(Theme.Typography.mono(15, weight: .semibold))
                    .foregroundStyle(Theme.Colors.coral)

                VStack(alignment: .leading, spacing: 2) {
                    Text(stop.venue.name)
                        .font(Theme.Typography.display(21, weight: .bold))
                        .foregroundStyle(Theme.Colors.ink)

                    HStack(spacing: 4) {
                        Text(stop.venue.category)
                        if let priceLevel = stop.venue.priceLevel {
                            Text("·")
                            Text(String(repeating: "$", count: max(priceLevel, 1)))
                        }
                    }
                    .font(Theme.Typography.display(14, weight: .medium))
                    .foregroundStyle(Theme.Colors.mauve)
                }

                if let address = stop.venue.address {
                    Text(address)
                        .font(.footnote)
                        .foregroundStyle(Theme.Colors.mauve)
                }
            }
            .padding(Theme.Spacing.md)

            TicketNotchDivider()

            HStack(spacing: Theme.Spacing.sm) {
                Button {
                    onFeedback(.accepted)
                } label: {
                    Label("Keep", systemImage: "hand.thumbsup.fill")
                }
                .buttonStyle(TicketActionButtonStyle(tint: Theme.Colors.sage))

                Button {
                    onFeedback(.rejected)
                } label: {
                    Label("Skip", systemImage: "hand.thumbsdown.fill")
                }
                .buttonStyle(TicketActionButtonStyle(tint: Theme.Colors.mauve))

                if !stop.alternates.isEmpty {
                    Button(action: onSwap) {
                        Label("Swap", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(TicketActionButtonStyle(tint: Theme.Colors.coral))
                }
            }
            .padding(Theme.Spacing.md)
        }
        .wtmCard()
    }

    private var timeRange: String {
        "\(stop.startTime.formatted(date: .omitted, time: .shortened)) – \(stop.endTime.formatted(date: .omitted, time: .shortened))"
    }
}

private struct TicketActionButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.display(13, weight: .bold))
            .padding(.horizontal, Theme.Spacing.sm + 2)
            .padding(.vertical, Theme.Spacing.sm)
            .foregroundStyle(tint)
            .background(tint.opacity(configuration.isPressed ? 0.24 : 0.12))
            .clipShape(Capsule())
    }
}
