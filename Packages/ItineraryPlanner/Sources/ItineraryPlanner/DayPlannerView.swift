import Foundation
import SwiftUI
import WTMCore

// MARK: - Domain model
//
// Ported from a self-contained React prototype (`Itinerary.js`). Deliberately
// independent of WTMCore's `Venue`/`Itinerary` types and `ItineraryServicing`:
// there is no persistence here, no venue catalog API, and no real drive-time
// service yet — this is the "building" experience for an ad hoc day plan,
// with everything hardcoded until those real backends exist. The critical
// property carried over from the original: no timing is ever stored. Drive
// times are a pure function of two venues; clock times are a pure function
// of everything before them. Add, remove, or swap a stop and the whole day
// recalculates from `dayStartMinute`.

struct PlannerVenue: Identifiable, Hashable {
    let id: UUID
    var name: String
    var category: String
    var durationMin: Int
    var rating: Double
    var lat: Double
    var lng: Double
    var why: String
    var note: String?
}

struct PlannerSlot: Identifiable, Hashable {
    let id: UUID
    var venue: PlannerVenue
    var alternatives: [PlannerVenue]
    /// Minutes since midnight, set only when the user has directly pinned
    /// this stop's start time. `nil` means "let the schedule compute it" —
    /// the default for every stop. A pin only ever pushes a start *later*
    /// than what's physically possible (see `schedule`); it never causes an
    /// overlap with the stop before it.
    var manualStartMinute: Int? = nil
}

/// Derived, never stored: a slot's position in the schedule, computed fresh
/// every time `slots` changes.
struct TimedPlannerSlot: Identifiable {
    var id: UUID { slot.id }
    let slot: PlannerSlot
    let startsAtMinute: Int
    let travelToNextMin: Int?
}

struct CatalogGroup: Identifiable {
    let key: String
    var id: String { key }
    let label: String
    let blurb: String
    let options: [PlannerVenue]
}

/// Where a new stop goes. Replaces the original's overloaded `addAfter: Int`
/// (where `-1` meant "insert at the front" for two different reasons) with
/// an explicit case.
enum InsertionPoint: Hashable {
    case start
    case after(Int)
}

// MARK: - Drive time

/// Stands in for a real routing call (e.g. the Distance Matrix API): same
/// inputs, same output shape, much worse answer. Isolated behind a protocol
/// so a real implementation drops in without touching call sites.
protocol DriveTimeEstimating {
    func driveMinutes(from a: PlannerVenue, to b: PlannerVenue) -> Int
}

struct HaversineDriveTimeEstimator: DriveTimeEstimating {
    func driveMinutes(from a: PlannerVenue, to b: PlannerVenue) -> Int {
        // Equirectangular approximation, tuned for neighbourhood scale.
        // Uses `a.lat` for the cosine term, so this is not quite symmetric
        // (`driveMinutes(a,b) != driveMinutes(b,a)` by a negligible amount)
        // — harmless here, kept intentionally to match the reference numbers.
        let latMiles = (a.lat - b.lat) * 69
        let lngMiles = (a.lng - b.lng) * 69 * cos(a.lat * .pi / 180)
        let miles = (latMiles * latMiles + lngMiles * lngMiles).squareRoot()
        // 18 mph models LA surface streets door to door; +2.5 min is parking.
        return max(3, Int((miles / 18 * 60 + 2.5).rounded()))
    }
}

// MARK: - Schedule

private let dayStartMinute = 660 // 11:00 AM

private func schedule(_ slots: [PlannerSlot], driveTimeEstimator: DriveTimeEstimating) -> [TimedPlannerSlot] {
    var previousEnd: Int?
    var result: [TimedPlannerSlot] = []

    for (index, slot) in slots.enumerated() {
        // The first stop has no physical constraint (a pin can move it
        // anywhere, effectively redefining when the day starts). Every
        // later stop can't start before the previous one plus drive time —
        // a pin can only push it later than that, never overlap it.
        let earliestFeasible = previousEnd ?? 0
        let naturalStart = previousEnd ?? dayStartMinute
        let startsAt = max(slot.manualStartMinute ?? naturalStart, earliestFeasible)

        let travel = index < slots.count - 1
            ? driveTimeEstimator.driveMinutes(from: slot.venue, to: slots[index + 1].venue)
            : nil
        result.append(TimedPlannerSlot(slot: slot, startsAtMinute: startsAt, travelToNextMin: travel))

        previousEnd = startsAt + slot.venue.durationMin + (travel ?? 0)
    }
    return result
}

// MARK: - Formatting

enum PlannerFormat {
    /// 12-hour clock. The original wraps silently past midnight
    /// (`hour24 % 24`, no rollover indicator) — fixed here by surfacing
    /// `isNextDay` so the UI can flag it instead of mislabeling a 2 AM stop
    /// as 2 AM the same day.
    static func clock(_ totalMinutes: Int) -> (hour: String, period: String, isNextDay: Bool) {
        let minutesPerDay = 24 * 60
        let isNextDay = totalMinutes >= minutesPerDay
        let minuteOfDay = ((totalMinutes % minutesPerDay) + minutesPerDay) % minutesPerDay
        let hour24 = minuteOfDay / 60
        let minute = minuteOfDay % 60
        let period = hour24 < 12 ? "AM" : "PM"
        var hour12 = hour24 % 12
        if hour12 == 0 { hour12 = 12 }
        return ("\(hour12):\(String(format: "%02d", minute))", period, isNextDay)
    }

    static func duration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours == 0 { return "\(remainder) min" }
        if remainder == 0 { return "\(hours) hr" }
        return "\(hours) hr \(remainder) min"
    }

    static func rating(_ value: Double) -> String {
        String(format: "★ %.1f", value)
    }
}

// MARK: - View model

@MainActor
@Observable
final class DayPlannerViewModel {
    var slots: [PlannerSlot]
    var swapSlotID: UUID?
    var addInsertionPoint: InsertionPoint?
    var editingTimeSlotID: UUID?

    let driveTimeEstimator: DriveTimeEstimating

    init(
        slots: [PlannerSlot] = PlannerSampleData.initialSlots(),
        driveTimeEstimator: DriveTimeEstimating = HaversineDriveTimeEstimator()
    ) {
        self.slots = slots
        self.driveTimeEstimator = driveTimeEstimator
    }

    var timeline: [TimedPlannerSlot] {
        schedule(slots, driveTimeEstimator: driveTimeEstimator)
    }

    var totalMinutes: Int {
        timeline.reduce(0) { $0 + $1.slot.venue.durationMin + ($1.travelToNextMin ?? 0) }
    }

    var swapTimedSlot: TimedPlannerSlot? {
        guard let swapSlotID else { return nil }
        return timeline.first { $0.id == swapSlotID }
    }

    var editingTimedSlot: TimedPlannerSlot? {
        guard let editingTimeSlotID else { return nil }
        return timeline.first { $0.id == editingTimeSlotID }
    }

    /// Every swap is undoable: the venue you replaced becomes the first
    /// alternative, stamped so it reads as the prior pick. The alternatives
    /// count stays constant across swaps. Note the swapped-in venue keeps
    /// whatever `note` it already had (e.g. "Quieter") even though it's now
    /// the active pick — preserved from the original rather than fixed.
    func swap(slotID: UUID, to chosen: PlannerVenue) {
        guard let index = slots.firstIndex(where: { $0.id == slotID }) else { return }
        var outgoing = slots[index].venue
        outgoing.note = "Previous pick"
        var remaining = slots[index].alternatives.filter { $0.id != chosen.id }
        remaining.insert(outgoing, at: 0)
        slots[index].venue = chosen
        slots[index].alternatives = remaining
        swapSlotID = nil
    }

    /// Pins a stop's start time to the picked clock time. If that clock
    /// time has already passed given everything before it (e.g. the
    /// previous stop doesn't end until 2pm and you pick 11am), it rolls
    /// forward to the next occurrence of that time instead of creating an
    /// overlap — the same behavior calendar apps use when you pick a time
    /// earlier than "now".
    func setStartTime(slotID: UUID, hour: Int, minute: Int) {
        guard let index = slots.firstIndex(where: { $0.id == slotID }) else { return }
        let earliestFeasible = earliestFeasibleStart(at: index)
        let pickedMinuteOfDay = hour * 60 + minute
        let dayBase = (earliestFeasible / 1440) * 1440
        var resolved = dayBase + pickedMinuteOfDay
        if resolved < earliestFeasible { resolved += 1440 }
        slots[index].manualStartMinute = resolved
    }

    func clearManualStart(slotID: UUID) {
        guard let index = slots.firstIndex(where: { $0.id == slotID }) else { return }
        slots[index].manualStartMinute = nil
    }

    /// The earliest a stop at `index` could possibly start: right after the
    /// previous stop ends plus drive time, or unconstrained (0) for the
    /// first stop.
    private func earliestFeasibleStart(at index: Int) -> Int {
        guard index > 0 else { return 0 }
        let timedSlots = timeline
        guard timedSlots.indices.contains(index - 1) else { return 0 }
        let previous = timedSlots[index - 1]
        return previous.startsAtMinute + previous.slot.venue.durationMin + (previous.travelToNextMin ?? 0)
    }

    func addStop(_ venue: PlannerVenue, alternatives: [PlannerVenue], at insertionPoint: InsertionPoint) {
        let newSlot = PlannerSlot(id: UUID(), venue: venue, alternatives: alternatives)
        switch insertionPoint {
        case .start:
            slots.insert(newSlot, at: 0)
        case .after(let index):
            slots.insert(newSlot, at: min(index + 1, slots.count))
        }
        addInsertionPoint = nil
    }

    /// No confirmation, no undo — matches the original. Also matches its
    /// "expansion state lost on removal" behavior for free: each row owns
    /// its own `isOpen`, so removing a slot's id just removes that state
    /// along with the row.
    func removeStop(id: UUID) {
        slots.removeAll { $0.id == id }
        swapSlotID = nil
    }
}

// MARK: - Screen

private let railWidth: CGFloat = 62

/// The "building" view for a day plan: a vertical timeline you edit
/// directly — add a stop at either end or between two existing stops,
/// expand a stop to see why it was picked, swap it, or remove it.
/// Deliberately distinct from `ItineraryView`, which is the read-mostly
/// "keep/skip/swap" view used once a group's real, generated itinerary
/// exists.
public struct DayPlannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = DayPlannerViewModel()
    @State private var planName: String
    @State private var neighbourhood: String
    @State private var isRenamingPlan = false
    @State private var isRenamingNeighbourhood = false

    /// Which tab is currently selected in the parent `TabView`. Passed in
    /// (rather than read some other way) purely so `.onChange(of:)` below
    /// has something to react to — see the comment there for why.
    let activeTab: Int

    public init(planName: String, neighbourhood: String = "Silver Lake", activeTab: Int = 0) {
        _planName = State(initialValue: planName)
        _neighbourhood = State(initialValue: neighbourhood)
        self.activeTab = activeTab
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                header
                timeline
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(Theme.Colors.paper.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        // Defensive reset: dismissing a sheet and switching tabs in quick
        // succession can race, occasionally leaving one of these flags
        // stuck `true`. `TabView` keeps every tab's view tree alive rather
        // than destroying it when you switch away, so a stuck flag would
        // silently re-open that sheet the next time this tab is selected
        // again. `.onDisappear` doesn't help here — SwiftUI/TabView often
        // never fires appear/disappear lifecycle events on a tab that's
        // merely hidden behind another one, since the view is never
        // actually removed from the tree, just not drawn. `activeTab`
        // sidesteps that: it's a plain value passed down from the parent
        // `TabView`'s selection, so `.onChange` fires on the ordinary data
        // dependency whenever it's updated, independent of visibility.
        .onChange(of: activeTab) {
            isRenamingPlan = false
            isRenamingNeighbourhood = false
            viewModel.swapSlotID = nil
            viewModel.addInsertionPoint = nil
            viewModel.editingTimeSlotID = nil
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").font(.body.weight(.semibold))
                        Text("Home")
                    }
                }
            }
        }
        .sheet(isPresented: isSwapSheetPresented) {
            if let timedSlot = viewModel.swapTimedSlot {
                SwapSheet(
                    timedSlot: timedSlot,
                    neighbourhood: neighbourhood,
                    onSelect: { chosen in
                        withAnimation(.easeInOut) { viewModel.swap(slotID: timedSlot.id, to: chosen) }
                    },
                    onCancel: { viewModel.swapSlotID = nil }
                )
            }
        }
        .sheet(isPresented: isAddSheetPresented) {
            if let point = viewModel.addInsertionPoint {
                let context = insertionContext(for: point)
                AddSheet(
                    insertionEyebrow: context.eyebrow,
                    anchor: context.anchor,
                    catalog: PlannerSampleData.catalog(),
                    driveTimeEstimator: viewModel.driveTimeEstimator,
                    onAdd: { venue, alternatives in
                        withAnimation(.easeInOut) { viewModel.addStop(venue, alternatives: alternatives, at: point) }
                    },
                    onCancel: { viewModel.addInsertionPoint = nil }
                )
            }
        }
        .sheet(isPresented: isTimeEditSheetPresented) {
            if let timedSlot = viewModel.editingTimedSlot {
                TimeEditSheet(
                    timedSlot: timedSlot,
                    onSave: { hour, minute in
                        withAnimation(.easeInOut) { viewModel.setStartTime(slotID: timedSlot.id, hour: hour, minute: minute) }
                    },
                    onResetToAutomatic: {
                        withAnimation(.easeInOut) { viewModel.clearManualStart(slotID: timedSlot.id) }
                    },
                    onCancel: { viewModel.editingTimeSlotID = nil }
                )
                .presentationDetents([.height(440)])
            }
        }
        .sheet(isPresented: $isRenamingPlan) {
            RenameSheet(
                title: "Rename Plan",
                prompt: "What should this day be called?",
                initialValue: planName,
                onSave: {
                    planName = $0
                    isRenamingPlan = false
                },
                onCancel: { isRenamingPlan = false }
            )
        }
        .sheet(isPresented: $isRenamingNeighbourhood) {
            RenameSheet(
                title: "Change Neighbourhood",
                prompt: "Where's this day happening?",
                initialValue: neighbourhood,
                onSave: {
                    neighbourhood = $0
                    isRenamingNeighbourhood = false
                },
                onCancel: { isRenamingNeighbourhood = false }
            )
        }
    }

    private var isSwapSheetPresented: Binding<Bool> {
        Binding(get: { viewModel.swapSlotID != nil }, set: { if !$0 { viewModel.swapSlotID = nil } })
    }

    private var isAddSheetPresented: Binding<Bool> {
        Binding(get: { viewModel.addInsertionPoint != nil }, set: { if !$0 { viewModel.addInsertionPoint = nil } })
    }

    private var isTimeEditSheetPresented: Binding<Bool> {
        Binding(get: { viewModel.editingTimeSlotID != nil }, set: { if !$0 { viewModel.editingTimeSlotID = nil } })
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Button(action: { isRenamingNeighbourhood = true }) {
                HStack(spacing: 4) {
                    EyebrowLabel(neighbourhood)
                    Image(systemName: "pencil")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.Colors.coral.opacity(0.6))
                }
            }
            .buttonStyle(.plain)

            Button(action: { isRenamingPlan = true }) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(planName)
                        .font(Theme.Typography.hero)
                        .foregroundStyle(Theme.Colors.ink)
                    Image(systemName: "pencil")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.Colors.mauve)
                }
            }
            .buttonStyle(.plain)

            Text(metaText)
                .font(Theme.Typography.display(15, weight: .medium))
                .foregroundStyle(Theme.Colors.mauve)
        }
    }

    private var metaText: String {
        let slots = viewModel.slots
        guard !slots.isEmpty else { return "Nothing planned yet" }
        let stopsText = slots.count == 1 ? "1 stop" : "\(slots.count) stops"
        return "\(stopsText) · \(PlannerFormat.duration(viewModel.totalMinutes))"
    }

    private var timeline: some View {
        let timedSlots = viewModel.timeline

        return VStack(alignment: .leading, spacing: 0) {
            if !timedSlots.isEmpty {
                AddRow(label: "Add a stop at the start") {
                    viewModel.addInsertionPoint = .start
                }
            }

            ForEach(Array(timedSlots.enumerated()), id: \.element.id) { index, timedSlot in
                StopRow(
                    timedSlot: timedSlot,
                    onEditTime: { viewModel.editingTimeSlotID = timedSlot.id },
                    onSwap: { viewModel.swapSlotID = timedSlot.id },
                    onRemove: { withAnimation(.easeInOut) { viewModel.removeStop(id: timedSlot.id) } }
                )

                if let travel = timedSlot.travelToNextMin {
                    TravelRow(minutes: travel) {
                        viewModel.addInsertionPoint = .after(index)
                    }
                } else {
                    Spacer().frame(height: 16)
                }
            }

            AddRow(label: timedSlots.isEmpty ? "Add your first stop" : "Add a stop at the end") {
                viewModel.addInsertionPoint = timedSlots.isEmpty ? .start : .after(timedSlots.count - 1)
            }
        }
    }

    private func insertionContext(for point: InsertionPoint) -> (eyebrow: String, anchor: PlannerVenue?) {
        let slots = viewModel.slots
        switch point {
        case .start:
            return ("Start of the day", slots.first?.venue)
        case .after(let index):
            guard slots.indices.contains(index) else { return ("Start of the day", nil) }
            if index == slots.count - 1 {
                return ("End of the day", slots[index].venue)
            }
            return ("After \(slots[index].venue.name)", slots[index].venue)
        }
    }
}

/// Draws the continuous vertical thread down the timeline. Applied per-row
/// rather than once for the whole stack, so each row's background simply
/// fills that row's own resolved height instead of needing to know the full
/// timeline's height up front (which would require an unbounded-height
/// hack inside a `ScrollView`).
private extension View {
    func timelineTrack() -> some View {
        background(alignment: .leading) {
            Rectangle()
                .fill(Theme.Colors.hairline)
                .frame(width: 1.5)
                .padding(.leading, railWidth / 2 - 0.75)
        }
    }
}

private struct AddRow: View {
    let label: String
    let action: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.sm) {
            Circle()
                .strokeBorder(Theme.Colors.mauve.opacity(0.5), lineWidth: 1.5)
                .background(Circle().fill(Theme.Colors.paper))
                .frame(width: 10, height: 10)
                .frame(width: railWidth, alignment: .center)

            Button(action: action) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "plus").font(.system(size: 13, weight: .bold))
                    Text(label).font(Theme.Typography.display(15, weight: .semibold))
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

private struct StopRow: View {
    let timedSlot: TimedPlannerSlot
    let onEditTime: () -> Void
    let onSwap: () -> Void
    let onRemove: () -> Void

    // Owned by the row, not lifted to the parent — matches the original,
    // and means expansion state naturally disappears when a stop is removed.
    @State private var isOpen = false

    private var slot: PlannerSlot { timedSlot.slot }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            railColumn
            SwipeToDelete(onDelete: onRemove) { cardColumn }
        }
        .padding(.vertical, Theme.Spacing.xs)
        .timelineTrack()
    }

    private var railColumn: some View {
        let clock = PlannerFormat.clock(timedSlot.startsAtMinute)
        return VStack(spacing: 6) {
            Button(action: onEditTime) {
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        Text(clock.hour)
                            .font(Theme.Typography.display(14, weight: .bold))
                            .foregroundStyle(Theme.Colors.ink)
                        if clock.isNextDay {
                            Text("+1")
                                .font(Theme.Typography.display(9, weight: .bold))
                                .foregroundStyle(Theme.Colors.coral)
                        }
                    }
                    HStack(spacing: 2) {
                        Text(clock.period)
                            .font(Theme.Typography.display(9, weight: .semibold))
                            .foregroundStyle(Theme.Colors.mauve)
                        if slot.manualStartMinute != nil {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 7))
                                .foregroundStyle(Theme.Colors.coral)
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            Circle()
                .fill(isOpen ? Theme.Colors.coral : Theme.Colors.paper)
                .frame(width: 11, height: 11)
                .overlay(Circle().strokeBorder(Theme.Colors.coral, lineWidth: 2.5))
        }
        .frame(width: railWidth, alignment: .center)
        .padding(.top, 2)
    }

    private var cardColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut) { isOpen.toggle() }
            } label: {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(slot.venue.name)
                            .font(Theme.Typography.display(19, weight: .bold))
                            .foregroundStyle(Theme.Colors.ink)
                        Text(slot.venue.category.uppercased())
                            .font(Theme.Typography.eyebrow)
                            .tracking(1)
                            .foregroundStyle(Theme.Colors.mauve)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.footnote.bold())
                        .foregroundStyle(Theme.Colors.mauve)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                }
                .padding(Theme.Spacing.md)
            }
            .buttonStyle(.plain)

            if isOpen {
                expandedDetails
            }
        }
        .wtmCard()
    }

    private var expandedDetails: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Divider()

            HStack(spacing: Theme.Spacing.xl) {
                statColumn(label: "Duration", value: PlannerFormat.duration(slot.venue.durationMin))
                statColumn(label: "Rating", value: PlannerFormat.rating(slot.venue.rating))
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                EyebrowLabel("Why this one")
                Text(slot.venue.why)
                    .font(Theme.Typography.display(14, weight: .medium))
                    .foregroundStyle(Theme.Colors.ink)
            }

            Button(action: onSwap) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Not what you want?")
                        .font(Theme.Typography.display(14, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink)
                    Text("\(slot.alternatives.count) other option\(slot.alternatives.count == 1 ? "" : "s")")
                        .font(Theme.Typography.display(13, weight: .medium))
                        .foregroundStyle(Theme.Colors.coral)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button("Remove this stop", action: onRemove)
                .font(Theme.Typography.display(14, weight: .semibold))
                .foregroundStyle(.red)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.md)
    }

    private func statColumn(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            EyebrowLabel(label)
            Text(value)
                .font(Theme.Typography.display(16, weight: .bold))
                .foregroundStyle(Theme.Colors.ink)
        }
    }
}

/// A quicker path to remove a stop than expanding it: drag the card left to
/// reveal a Delete action, mirroring `List`'s built-in swipe actions — which
/// aren't available here since this timeline isn't a `List`.
private struct SwipeToDelete<Content: View>: View {
    let onDelete: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var revealed = false
    @GestureState private var dragTranslation: CGFloat = 0

    private let revealWidth: CGFloat = 84

    var body: some View {
        let baseOffset = revealed ? -revealWidth : 0

        content()
            .offset(x: baseOffset + dragTranslation)
            // `.background`, not `ZStack` — a `ZStack` sizes itself to its
            // *largest* child, and the delete button below wants
            // `maxHeight: .infinity`. Inside a `ScrollView` (unbounded
            // height proposal), that would balloon this whole row to a huge
            // size instead of the card's normal height. `.background` sizes
            // its content to match the view it's attached to instead, so
            // the button just fills whatever height `content()` resolves
            // to — same visual effect, no layout blowup.
            .background(alignment: .trailing) {
                Button(action: onDelete) {
                    VStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                        Text("Delete").font(.caption2.bold())
                    }
                    .foregroundStyle(.white)
                    .frame(width: revealWidth)
                    .frame(maxHeight: .infinity)
                }
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            }
            // `.simultaneousGesture`, not `.gesture` — a plain `.gesture`
            // claims the touch exclusively as soon as it recognizes any
            // movement, which blocked the ScrollView's own vertical pan
            // even though the closure below only *acts* on horizontal
            // drags. Simultaneous recognition lets both live side by side.
            .simultaneousGesture(
                DragGesture(minimumDistance: 12)
                    .updating($dragTranslation) { value, state, _ in
                        // Only claim the gesture once it's clearly more
                        // horizontal than vertical, so the ScrollView's own
                        // vertical scroll gesture still wins on a normal
                        // up/down swipe.
                        guard abs(value.translation.width) > abs(value.translation.height) else { return }
                        let clampedTotal = min(0, max(baseOffset + value.translation.width, -revealWidth))
                        state = clampedTotal - baseOffset
                    }
                    .onEnded { value in
                        guard abs(value.translation.width) > abs(value.translation.height) else { return }
                        let clampedTotal = min(0, max(baseOffset + value.translation.width, -revealWidth))
                        withAnimation(.easeOut) {
                            revealed = clampedTotal < -revealWidth / 2
                        }
                    }
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }
}

private struct TravelRow: View {
    let minutes: Int
    let onInsert: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Spacer().frame(width: railWidth)

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

// MARK: - Rename sheet

// Every sheet below takes an explicit `onCancel` (and folds dismissal into
// `onSave`/`onSelect`) instead of calling its own `@Environment(\.dismiss)`.
// The alternative — a sheet dismissing itself and relying on that to
// propagate back and flip the presenting view's `@State` boolean to
// `false` — is a cross-view round trip that can race with something else
// happening to the presenting view at the same moment (e.g. a `TabView`
// switching tabs right as Cancel is tapped), occasionally leaving the flag
// stuck `true` and the sheet reappearing later. Calling an explicit closure
// that sets the parent's own state directly, in the same view that owns
// it, can't be lost that way.
private struct RenameSheet: View {
    let title: String
    let prompt: String
    let onSave: (String) -> Void
    let onCancel: () -> Void

    @State private var text: String

    init(title: String, prompt: String, initialValue: String, onSave: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.title = title
        self.prompt = prompt
        self.onSave = onSave
        self.onCancel = onCancel
        _text = State(initialValue: initialValue)
    }

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                Text(prompt)
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.mauve)

                TextField(title, text: $text)
                    .textFieldStyle(.wtmCard)
                    .textInputAutocapitalization(.words)

                Button("Save") { onSave(trimmed) }
                    .buttonStyle(.wtmPrimary)
                    .disabled(trimmed.isEmpty)

                Spacer()
            }
            .padding(Theme.Spacing.lg)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
        .presentationDetents([.height(280)])
    }
}

// MARK: - Time edit sheet

private struct TimeEditSheet: View {
    let timedSlot: TimedPlannerSlot
    let onSave: (Int, Int) -> Void
    let onResetToAutomatic: () -> Void
    let onCancel: () -> Void

    @State private var selection: Date

    init(
        timedSlot: TimedPlannerSlot,
        onSave: @escaping (Int, Int) -> Void,
        onResetToAutomatic: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.timedSlot = timedSlot
        self.onSave = onSave
        self.onResetToAutomatic = onResetToAutomatic
        self.onCancel = onCancel
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        let minuteOfDay = ((timedSlot.startsAtMinute % 1440) + 1440) % 1440
        _selection = State(initialValue: calendar.date(byAdding: .minute, value: minuteOfDay, to: startOfToday) ?? .now)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                Text(timedSlot.slot.venue.name)
                    .font(Theme.Typography.display(15, weight: .semibold))
                    .foregroundStyle(Theme.Colors.mauve)

                DatePicker("Start time", selection: $selection, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()

                Button("Set Time") {
                    let comps = Calendar.current.dateComponents([.hour, .minute], from: selection)
                    onSave(comps.hour ?? 0, comps.minute ?? 0)
                }
                .buttonStyle(.wtmPrimary)

                if timedSlot.slot.manualStartMinute != nil {
                    Button("Use Automatic Timing", action: onResetToAutomatic)
                        .buttonStyle(.wtmSecondary)
                }
            }
            .padding(Theme.Spacing.lg)
            .navigationTitle("Adjust Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }
}

// MARK: - Swap sheet

private struct SwapSheet: View {
    let timedSlot: TimedPlannerSlot
    let neighbourhood: String
    let onSelect: (PlannerVenue) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.paper.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            EyebrowLabel("\(clockText) · \(neighbourhood)")
                            Text("Swap this stop")
                                .font(Theme.Typography.title)
                                .foregroundStyle(Theme.Colors.ink)
                        }

                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            EyebrowLabel("Currently planned")
                            currentCard
                        }

                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            EyebrowLabel("Instead, you could")
                            VStack(spacing: Theme.Spacing.sm) {
                                ForEach(timedSlot.slot.alternatives) { alternative in
                                    VenueOptionCard(venue: alternative, metaLine: metaLine(for: alternative)) {
                                        onSelect(alternative)
                                    }
                                }
                            }
                        }

                        Text("Drive times and later stops recalculate around whatever you pick.")
                            .font(.footnote)
                            .foregroundStyle(Theme.Colors.mauve)
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }

    private var clockText: String {
        let clock = PlannerFormat.clock(timedSlot.startsAtMinute)
        return "\(clock.hour) \(clock.period)"
    }

    private var currentCard: some View {
        let venue = timedSlot.slot.venue
        return VStack(alignment: .leading, spacing: 4) {
            Text(venue.name)
                .font(Theme.Typography.display(18, weight: .bold))
                .foregroundStyle(Theme.Colors.ink)
            Text(metaLine(for: venue))
                .font(Theme.Typography.display(13, weight: .medium))
                .foregroundStyle(Theme.Colors.mauve)
        }
        .padding(Theme.Spacing.md)
        .wtmCard()
    }

    private func metaLine(for venue: PlannerVenue) -> String {
        "\(venue.category) · \(PlannerFormat.duration(venue.durationMin)) · \(PlannerFormat.rating(venue.rating))"
    }
}

private struct VenueOptionCard: View {
    let venue: PlannerVenue
    let metaLine: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                    Text(venue.name)
                        .font(Theme.Typography.display(17, weight: .bold))
                        .foregroundStyle(Theme.Colors.ink)
                    if let note = venue.note {
                        Text(note)
                            .font(Theme.Typography.display(11, weight: .bold))
                            .foregroundStyle(Theme.Colors.coral)
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, 3)
                            .background(Theme.Colors.coralWash)
                            .clipShape(Capsule())
                    }
                    Spacer()
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(Theme.Colors.coral)
                }
                Text(metaLine)
                    .font(Theme.Typography.display(13, weight: .medium))
                    .foregroundStyle(Theme.Colors.mauve)
                Text(venue.why)
                    .font(Theme.Typography.display(13, weight: .medium))
                    .foregroundStyle(Theme.Colors.ink)
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .wtmCard()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add sheet

private struct AddSheet: View {
    let insertionEyebrow: String
    let anchor: PlannerVenue?
    let catalog: [CatalogGroup]
    let driveTimeEstimator: DriveTimeEstimating
    let onAdd: (PlannerVenue, [PlannerVenue]) -> Void
    let onCancel: () -> Void

    // Owned by the sheet; resets for free each time the sheet is
    // re-presented, since SwiftUI gives it a fresh `@State` instance.
    @State private var selectedGroupKey: String?

    private var selectedGroup: CatalogGroup? {
        catalog.first { $0.key == selectedGroupKey }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.paper.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        header

                        if let selectedGroup {
                            optionsList(for: selectedGroup)
                        } else {
                            categoryGrid
                        }
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            EyebrowLabel(insertionEyebrow)

            if let selectedGroup {
                Button {
                    withAnimation(.easeInOut) { selectedGroupKey = nil }
                } label: {
                    Label("All categories", systemImage: "chevron.left")
                        .font(Theme.Typography.display(14, weight: .semibold))
                        .foregroundStyle(Theme.Colors.coral)
                }
                .buttonStyle(.plain)

                Text(selectedGroup.label)
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Colors.ink)
            } else {
                Text("What are you adding?")
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Colors.ink)
            }
        }
    }

    private var categoryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: Theme.Spacing.sm), GridItem(.flexible())], spacing: Theme.Spacing.sm) {
            ForEach(catalog) { group in
                Button {
                    withAnimation(.easeInOut) { selectedGroupKey = group.key }
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.label)
                            .font(Theme.Typography.display(16, weight: .bold))
                            .foregroundStyle(Theme.Colors.ink)
                        Text(group.blurb)
                            .font(.footnote)
                            .foregroundStyle(Theme.Colors.mauve)
                        Spacer(minLength: Theme.Spacing.sm)
                        Text("\(group.options.count) nearby")
                            .font(Theme.Typography.display(12, weight: .semibold))
                            .foregroundStyle(Theme.Colors.coral)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.Spacing.md)
                    .frame(height: 120, alignment: .topLeading)
                    .wtmCard()
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func optionsList(for group: CatalogGroup) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(group.options) { option in
                VenueOptionCard(venue: option, metaLine: metaLine(for: option)) {
                    onAdd(option, group.options.filter { $0.id != option.id })
                }
            }
        }
    }

    private func metaLine(for option: PlannerVenue) -> String {
        var text = "\(option.category) · \(PlannerFormat.duration(option.durationMin)) · \(PlannerFormat.rating(option.rating))"
        if let anchor {
            text += " · \(driveTimeEstimator.driveMinutes(from: anchor, to: option)) min away"
        }
        return text
    }
}

#Preview {
    NavigationStack {
        DayPlannerView(planName: "Saturday afternoon")
    }
}
