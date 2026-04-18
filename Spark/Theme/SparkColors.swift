import SwiftUI
import UIKit

/// Semantic color tokens for Spark. Every view-layer color must come from here.
///
/// The accent is a single warm coral in the sunset family, used for interactive
/// and branded elements only. Everything else defers to the system so we get
/// correct dark-mode and high-contrast behavior for free.
enum SparkColors {
    // MARK: Accent

    /// The single warm accent. Coral in light mode, a slightly brighter coral
    /// in dark mode for contrast against `.black` backgrounds.
    static let accent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 1.00, green: 0.45, blue: 0.42, alpha: 1) // warm coral, brighter
            : UIColor(red: 0.98, green: 0.36, blue: 0.36, alpha: 1) // warm coral
    })

    /// A muted accent for tinted fills (selected chip background, celebratory row).
    /// Intended to be layered at the natural opacity \(\~0.12\) on a surface.
    static let accentMuted = accent.opacity(0.12)

    // MARK: Surfaces

    static let background = Color(.systemBackground)
    static let surface = Color(.secondarySystemBackground)
    static let surfaceElevated = Color(.tertiarySystemBackground)

    // MARK: Text

    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)

    // MARK: Semantic

    static let success = Color.green
    static let destructive = Color.red

    /// Used for "not tonight" / soft-decline actions. Never red.
    static let soft = Color(.tertiaryLabel)

    // MARK: Deprecated

    @available(*, deprecated, renamed: "textPrimary")
    static var primaryText: Color { textPrimary }

    @available(*, deprecated, renamed: "textSecondary")
    static var secondaryText: Color { textSecondary }

    @available(*, deprecated, renamed: "surface")
    static var secondaryBackground: Color { surface }

    @available(*, deprecated, renamed: "surface")
    static var cardBackground: Color { surface }
}
