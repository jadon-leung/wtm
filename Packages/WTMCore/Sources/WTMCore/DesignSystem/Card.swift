import SwiftUI

public struct CardBackground: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .strokeBorder(Theme.Colors.hairline, lineWidth: 1)
            )
    }
}

extension View {
    public func wtmCard() -> some View {
        modifier(CardBackground())
    }
}

/// Small-caps section label — "CUISINES", "MEMBERS" — used instead of
/// stock `Section` headers so headings read as this app's voice, not
/// UIKit's default gray-caps.
public struct EyebrowLabel: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text.uppercased())
            .font(Theme.Typography.eyebrow)
            .tracking(1.2)
            .foregroundStyle(Theme.Colors.coral)
    }
}
