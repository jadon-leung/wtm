import SwiftUI
import UIKit
import WTMCore

/// Configures UIKit appearance proxies once at launch so navigation bars
/// and tab bars pick up WTM's rounded type and coral tint instead of the
/// stock San Francisco / iOS-blue defaults — SwiftUI has no direct API for
/// large-title font family, so this is the one place we reach into UIKit.
@MainActor
enum AppearanceConfigurator {
    static func configure() {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(Theme.Colors.paper)
        navBarAppearance.shadowColor = .clear
        navBarAppearance.largeTitleTextAttributes = [
            .font: roundedFont(ofSize: 34, weight: .bold),
            .foregroundColor: UIColor(Theme.Colors.ink)
        ]
        navBarAppearance.titleTextAttributes = [
            .font: roundedFont(ofSize: 17, weight: .bold),
            .foregroundColor: UIColor(Theme.Colors.ink)
        ]

        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = UIColor(Theme.Colors.coral)

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Theme.Colors.surface)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = UIColor(Theme.Colors.coral)
    }

    private static func roundedFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = systemFont.fontDescriptor.withDesign(.rounded) else { return systemFont }
        return UIFont(descriptor: descriptor, size: size)
    }
}
