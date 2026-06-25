import SwiftUI
import UIKit

// MARK: - Hex initializer

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8)  & 0xFF) / 255,
            blue:  Double( hex        & 0xFF) / 255,
            opacity: 1)
    }
}

private extension UIColor {
    convenience init(hex: UInt) {
        self.init(
            red:   CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8)  & 0xFF) / 255,
            blue:  CGFloat( hex        & 0xFF) / 255,
            alpha: 1)
    }

    /// Builds a dynamic color that resolves differently in light vs. dark mode.
    static func dynamic(light: UInt, dark: UInt) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: dark)
                : UIColor(hex: light)
        }
    }
}

// MARK: - ACME palette
//
// The light values are the canonical ACME identity (warm paper). The dark
// values keep the same warmth on a near-black "ink" canvas so the editorial
// feel survives dark mode. Accent (clay) stays close to identical so the
// brand reads the same in both.

extension Color {
    static let paper        = Color(uiColor: .dynamic(light: 0xF4EFEB, dark: 0x141516)) // app canvas
    static let cream        = Color(uiColor: .dynamic(light: 0xFEFAF5, dark: 0x1F1E1D)) // cards / surfaces
    static let inkPrimary   = Color(uiColor: .dynamic(light: 0x1D1D1E, dark: 0xF2EFEA)) // headings, primary text
    static let inkSecondary = Color(uiColor: .dynamic(light: 0x7A7977, dark: 0x9C9A96)) // body, metadata
    static let hairline     = Color(uiColor: .dynamic(light: 0xDBDAD7, dark: 0x34322F)) // dividers, faint edges
    static let clay         = Color(uiColor: .dynamic(light: 0xD97D56, dark: 0xE08A63)) // accent / markers
    static let clayDeep     = Color(uiColor: .dynamic(light: 0xB5613D, dark: 0xC56E45)) // button fills, icon-on-peach
    static let peach        = Color(uiColor: .dynamic(light: 0xF2E0D2, dark: 0x3A2C22)) // icon-tile + alert backgrounds
    static let sun          = Color(uiColor: .dynamic(light: 0xF5CF00, dark: 0xF5CF00)) // one highlight, used sparingly

    /// Text color that sits on top of a clayDeep fill (always light).
    static let onClay       = Color(hex: 0xFEFAF5)
}
