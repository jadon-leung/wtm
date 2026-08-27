import SwiftUI

/// Pill-shaped multi-select control — replaces stock `List` checkmark rows
/// for picking cuisines/activities/restrictions, so choosing preferences
/// feels like tapping tags, not filling out a settings form.
public struct SelectableChip: View {
    private let title: String
    private let isSelected: Bool
    private let action: () -> Void

    public init(_ title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.display(14, weight: .semibold))
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .foregroundStyle(isSelected ? .white : Theme.Colors.ink)
                .background(isSelected ? Theme.Colors.coral : Theme.Colors.surface)
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.clear : Theme.Colors.hairline, lineWidth: 1.5)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Wraps chips onto multiple lines instead of a fixed-width `HStack`.
public struct ChipFlowLayout: Layout {
    public var spacing: CGFloat = Theme.Spacing.sm

    public init(spacing: CGFloat = Theme.Spacing.sm) {
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var origin = CGPoint.zero
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if origin.x + size.width > width, origin.x > 0 {
                origin.x = 0
                origin.y += rowHeight + spacing
                rowHeight = 0
            }
            origin.x += size.width + spacing
            maxX = max(maxX, origin.x - spacing)
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: maxX, height: origin.y + rowHeight)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = CGPoint(x: bounds.minX, y: bounds.minY)
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if origin.x + size.width > bounds.maxX, origin.x > bounds.minX {
                origin.x = bounds.minX
                origin.y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: origin, proposal: .unspecified)
            origin.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
