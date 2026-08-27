import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// WTM's visual identity: a "golden hour" palette — planning tonight's
/// hangout, not filing a form. Deep aubergine ink, warm paper background,
/// coral as the one loud color, sage/gold as quiet seconds.
public enum Theme {
    public enum Colors {
        public static let ink = Color.wtmAdaptive(light: 0x221B2E, dark: 0xF3EEF6)
        public static let paper = Color.wtmAdaptive(light: 0xF6F1F5, dark: 0x17121F)
        public static let surface = Color.wtmAdaptive(light: 0xFFFFFF, dark: 0x241C31)
        public static let coral = Color.wtmAdaptive(light: 0xFF5D48, dark: 0xFF7A63)
        public static let sage = Color.wtmAdaptive(light: 0x4F8272, dark: 0x7FB39E)
        public static let gold = Color.wtmAdaptive(light: 0xE7A33E, dark: 0xF0B85C)
        public static let mauve = Color.wtmAdaptive(light: 0x8B7E93, dark: 0x9E93A8)

        public static let hairline = mauve.opacity(0.25)
        public static let coralWash = coral.opacity(0.12)
    }

    public enum Typography {
        public static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
            .system(size: size, weight: weight, design: .rounded)
        }

        public static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
            .system(size: size, weight: weight, design: .monospaced)
        }

        public static let hero = display(36, weight: .black)
        public static let title = display(22, weight: .bold)
        public static let headline = display(17, weight: .bold)
        public static let eyebrow = Font.system(size: 12, weight: .bold, design: .rounded)
    }

    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
    }

    public enum Radius {
        public static let card: CGFloat = 20
        public static let control: CGFloat = 14
        public static let pill: CGFloat = 999
    }
}

extension Color {
    init(wtmHex hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    /// A color that switches its underlying hex value with the system
    /// appearance, without needing entries in an asset catalog — keeps the
    /// palette defined in one place, in code, shared by every package.
    static func wtmAdaptive(light: UInt32, dark: UInt32) -> Color {
        #if canImport(UIKit)
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(wtmHex: dark)) : UIColor(Color(wtmHex: light))
        })
        #else
        // Non-iOS build (e.g. `swift build`/`swift test` on macOS for CI):
        // this app never ships for macOS, so a static fallback is fine here.
        Color(wtmHex: light)
        #endif
    }
}
