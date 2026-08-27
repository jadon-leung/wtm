import SwiftUI

public struct PrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.display(16, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.sm + 4)
            .background(Theme.Colors.coral.opacity(configuration.isPressed ? 0.75 : 1))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
    }
}

public struct SecondaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.display(16, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.sm + 4)
            .foregroundStyle(Theme.Colors.ink)
            .background(Theme.Colors.surface.opacity(configuration.isPressed ? 0.6 : 1))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                    .strokeBorder(Theme.Colors.hairline, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
    }
}

public struct DestructiveButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.display(16, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.sm + 4)
            .foregroundStyle(.red)
            .background(Color.red.opacity(configuration.isPressed ? 0.16 : 0.1))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    public static var wtmPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    public static var wtmSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

extension ButtonStyle where Self == DestructiveButtonStyle {
    public static var wtmDestructive: DestructiveButtonStyle { DestructiveButtonStyle() }
}
