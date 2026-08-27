import SwiftUI

/// Rounded card-style field — replaces the plain-underline look `Form`
/// gives text fields by default.
public struct CardTextFieldStyle: TextFieldStyle {
    public init() {}

    public func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(Theme.Typography.display(16, weight: .medium))
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm + 4)
            .background(Theme.Colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                    .strokeBorder(Theme.Colors.hairline, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
            .foregroundStyle(Theme.Colors.ink)
    }
}

extension TextFieldStyle where Self == CardTextFieldStyle {
    public static var wtmCard: CardTextFieldStyle { CardTextFieldStyle() }
}
