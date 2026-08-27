import SwiftUI
import WTMCore

private let timelineTimeColumnWidth: CGFloat = 56

/// The "building" view for a day plan: a vertical timeline you edit
/// directly — add a stop at either end or between two existing stops,
/// expand a stop to swap or remove it. Deliberately distinct from
/// `ItineraryView`, which is the read-mostly "keep/skip/swap" view used by
/// the Groups and My Itinerary tabs once a plan is finalized.
public struct DayPlannerView: View {
    private let group: WTMGroup

    @Environment(\.services) private var services
    @State private var viewModel: ItineraryViewModel?
    @State private var swappingStop: ItineraryStop?
    @State private var addStopContext: AddStopContext?
    @State private var expandedStopID: UUID?

    public init(group: WTMGroup) {
        self.group = group
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
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil {
                let model = ItineraryViewModel(group: group, itineraryService: services.itinerary)
                viewModel = model
                await model.load()
                if model.itinerary == nil || model.itinerary?.stops.isEmpty == true {
                    await model.generate()
                }
            }
        }
        .sheet(item: $swappingStop) { stop in
            SwapVenueSheet(stop: stop) { alternate in
                swappingStop = nil
                Task { await viewModel?.swap(stop: stop, forAlternate: alternate) }
            }
        }
        .sheet(item: $addStopContext) { context in
            AddStopSheet(context: context) { name, category, duration in
                addStopContext = nil
                Task { await viewModel?.insertStop(named: name, category: category, durationMinutes: duration, at: context.index) }
            }
        }
    }

    @ViewBuilder
    private func content(for viewModel: ItineraryViewModel) -> some View {
        if viewModel.isGenerating || (viewModel.isLoading && viewModel.itinerary == nil) {
            VStack(spacing: Theme.Spacing.md) {
                ProgressView().tint(Theme.Colors.coral)
                Text(viewModel.isGenerating ? "Building your day…" : "Loading…")
                    .font(Theme.Typography.display(15, weight: .medium))
                    .foregroundStyle(Theme.Colors.mauve)
            }
        } else if let itinerary = viewModel.itinerary {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    header(for: itinerary)

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    timeline(for: itinerary, viewModel: viewModel)
                }
                .padding(Theme.Spacing.lg)
            }
        } else if let errorMessage = viewModel.errorMessage {
            VStack(spacing: Theme.Spacing.md) {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                Button("Retry") {
                    Task { await viewModel.generate() }
                }
                .buttonStyle(.wtmSecondary)
            }
            .padding(Theme.Spacing.lg)
        }
    }

    private func header(for itinerary: Itinerary) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            EyebrowLabel("Day Planner")
            Text(group.name)
                .font(Theme.Typography.hero)
                .foregroundStyle(Theme.Colors.ink)
            Text(summaryText(for: itinerary))
                .font(Theme.Typography.display(15, weight: .medium))
                .foregroundStyle(Theme.Colors.mauve)
        }
    }

    private func summaryText(for itinerary: Itinerary) -> String {
        let stops = itinerary.stops
        let stopsText = stops.count == 1 ? "1 stop" : "\(stops.count) stops"
        guard let start = stops.map(\.startTime).min(), let end = stops.map(\.endTime).max() else {
            return stopsText
        }
        let minutes = max(0, Int(end.timeIntervalSince(start) / 60))
        let hours = minutes / 60
        let remainder = minutes % 60
        let durationText: String
        if hours == 0 { durationText = "\(remainder) min" }
        else if remainder == 0 { durationText = "\(hours) hr" }
        else { durationText = "\(hours) hr \(remainder) min" }
        return "\(stopsText) · \(durationText)"
    }

    private func timeline(for itinerary: Itinerary, viewModel: ItineraryViewModel) -> some View {
        let stops = itinerary.stops.sorted { $0.order < $1.order }

        return VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            TimelineAnchorRow(label: "Add a stop at the start") {
                addStopContext = AddStopContext(index: 0, label: "at the start")
            }

            ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                TimelineStopRow(
                    stop: stop,
                    isExpanded: expandedStopID == stop.id,
                    onToggleExpand: {
                        withAnimation { expandedStopID = expandedStopID == stop.id ? nil : stop.id }
                    },
                    onSwap: { swappingStop = stop },
                    onRemove: { Task { await viewModel.removeStop(stop) } }
                )

                if index < stops.count - 1 {
                    TravelGapRow(
                        minutes: travelMinutes(from: stop, to: stops[index + 1]),
                        onInsert: { addStopContext = AddStopContext(index: index + 1, label: "here") }
                    )
                }
            }

            TimelineAnchorRow(label: "Add a stop at the end") {
                addStopContext = AddStopContext(index: stops.count, label: "at the end")
            }
        }
    }

    private func travelMinutes(from: ItineraryStop, to: ItineraryStop) -> Int {
        max(0, Int(to.startTime.timeIntervalSince(from.endTime) / 60))
    }
}

private struct AddStopContext: Identifiable {
    let index: Int
    let label: String
    var id: Int { index }
}

/// Draws the continuous vertical thread that runs down the timeline. Applied
/// per-row rather than once for the whole stack, so each row's background
/// simply fills that row's own resolved height instead of needing to know
/// the full timeline's height up front.
private extension View {
    func timelineTrack() -> some View {
        background(alignment: .leading) {
            Rectangle()
                .fill(Theme.Colors.hairline)
                .frame(width: 1.5)
                .padding(.leading, timelineTimeColumnWidth / 2 - 0.75)
        }
    }
}

private struct TimelineAnchorRow: View {
    let label: String
    let action: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.sm) {
            Circle()
                .strokeBorder(Theme.Colors.mauve.opacity(0.5), lineWidth: 1.5)
                .background(Circle().fill(Theme.Colors.paper))
                .frame(width: 10, height: 10)
                .frame(width: timelineTimeColumnWidth, alignment: .center)

            Button(action: action) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                    Text(label)
                        .font(Theme.Typography.display(15, weight: .semibold))
                }
                .foregroundStyle(Theme.Colors.coral)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm + 4)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                        .strokeBorder(Theme.Colors.coral.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, Theme.Spacing.xs)
        .timelineTrack()
    }
}

private struct TimelineStopRow: View {
    let stop: ItineraryStop
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onSwap: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            timeAndNode
                .frame(width: timelineTimeColumnWidth, alignment: .center)

            VStack(alignment: .leading, spacing: 0) {
                Button(action: onToggleExpand) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stop.venue.name)
                                .font(Theme.Typography.display(19, weight: .bold))
                                .foregroundStyle(Theme.Colors.ink)
                            Text(stop.venue.category.uppercased())
                                .font(Theme.Typography.eyebrow)
                                .tracking(1)
                                .foregroundStyle(Theme.Colors.mauve)
                        }
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.footnote.bold())
                            .foregroundStyle(Theme.Colors.mauve)
                    }
                    .padding(Theme.Spacing.md)
                }
                .buttonStyle(.plain)

                if isExpanded {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        if let address = stop.venue.address {
                            Text(address)
                                .font(.footnote)
                                .foregroundStyle(Theme.Colors.mauve)
                        }

                        HStack(spacing: Theme.Spacing.sm) {
                            if !stop.alternates.isEmpty {
                                Button(action: onSwap) {
                                    Label("Swap", systemImage: "arrow.triangle.2.circlepath")
                                }
                                .buttonStyle(TicketActionButtonStyle(tint: Theme.Colors.coral))
                            }

                            Button(action: onRemove) {
                                Label("Remove", systemImage: "trash")
                            }
                            .buttonStyle(TicketActionButtonStyle(tint: .red))
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.bottom, Theme.Spacing.md)
                }
            }
            .wtmCard()
        }
        .padding(.vertical, Theme.Spacing.xs)
        .timelineTrack()
    }

    private var timeAndNode: some View {
        let parts = stop.startTime.formatted(date: .omitted, time: .shortened).split(separator: " ")
        return VStack(spacing: 6) {
            Text(parts.first.map(String.init) ?? "")
                .font(Theme.Typography.display(15, weight: .bold))
                .foregroundStyle(Theme.Colors.ink)
            if parts.count > 1 {
                Text(parts[1])
                    .font(Theme.Typography.display(11, weight: .semibold))
                    .foregroundStyle(Theme.Colors.mauve)
            }
            Circle()
                .fill(Theme.Colors.coral)
                .frame(width: 12, height: 12)
                .overlay(Circle().strokeBorder(Theme.Colors.paper, lineWidth: 2))
        }
        .padding(.top, 2)
    }
}

private struct TravelGapRow: View {
    let minutes: Int
    let onInsert: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Spacer().frame(width: timelineTimeColumnWidth)

            Text("\(minutes) min drive")
                .font(Theme.Typography.display(13, weight: .semibold))
                .foregroundStyle(Theme.Colors.coral)
                .padding(.horizontal, Theme.Spacing.sm + 2)
                .padding(.vertical, 6)
                .background(Theme.Colors.coralWash)
                .clipShape(Capsule())

            Button(action: onInsert) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.Colors.mauve)
                    .frame(width: 28, height: 28)
                    .overlay(Circle().strokeBorder(Theme.Colors.hairline, lineWidth: 1.5))
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.vertical, Theme.Spacing.xs)
        .timelineTrack()
    }
}

private struct AddStopSheet: View {
    let context: AddStopContext
    let onAdd: (String, String, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var category = ""
    @State private var durationMinutes = 60

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.paper.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            TextField("Place name", text: $name)
                                .textFieldStyle(.wtmCard)
                            TextField("Category, e.g. Coffee", text: $category)
                                .textFieldStyle(.wtmCard)
                        }

                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            EyebrowLabel("Duration")
                            Stepper(value: $durationMinutes, in: 15...240, step: 15) {
                                Text("\(durationMinutes) min")
                                    .font(Theme.Typography.display(16, weight: .semibold))
                                    .foregroundStyle(Theme.Colors.ink)
                            }
                            .padding(Theme.Spacing.md)
                            .wtmCard()
                        }

                        Button("Add Stop") {
                            onAdd(
                                name.trimmingCharacters(in: .whitespaces),
                                category.trimmingCharacters(in: .whitespaces).isEmpty ? "Stop" : category,
                                durationMinutes
                            )
                        }
                        .buttonStyle(.wtmPrimary)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .navigationTitle("Add a Stop \(context.label)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DayPlannerView(group: WTMGroup(id: UUID(), name: "Saturday afternoon", createdBy: UUID(), inviteCode: "AB12CD"))
            .environment(\.services, .mock)
    }
}
