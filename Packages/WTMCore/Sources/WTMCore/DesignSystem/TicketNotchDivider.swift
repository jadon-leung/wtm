import SwiftUI

/// The perforated divider between a ticket's stub and its body — two
/// half-circle "punches" at the card's edges plus a dashed tear line.
/// Meant to sit inside a view already clipped to `Theme.Radius.card`, with
/// its container's background matching `backgroundColor` so the punches
/// read as cutouts rather than solid dots.
public struct TicketNotchDivider: View {
    private let backgroundColor: Color

    public init(backgroundColor: Color = Theme.Colors.paper) {
        self.backgroundColor = backgroundColor
    }

    public var body: some View {
        GeometryReader { proxy in
            let midY = proxy.size.height / 2
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: 20, y: midY))
                    path.addLine(to: CGPoint(x: proxy.size.width - 20, y: midY))
                }
                .stroke(Theme.Colors.hairline, style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))

                Circle()
                    .fill(backgroundColor)
                    .frame(width: 20, height: 20)
                    .position(x: 0, y: midY)

                Circle()
                    .fill(backgroundColor)
                    .frame(width: 20, height: 20)
                    .position(x: proxy.size.width, y: midY)
            }
        }
        .frame(height: 20)
    }
}
