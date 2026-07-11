// Color+DesignSystem.swift
//
// SwiftUI color tokens for the "Technical Luxury" system specified in DESIGN.md.

import SwiftUI

private extension Color {
    init(hex: String) {
        let hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&value)

        let r, g, b, a: Double
        switch hexString.count {
        case 8:
            r = Double((value >> 24) & 0xFF) / 255
            g = Double((value >> 16) & 0xFF) / 255
            b = Double((value >> 8) & 0xFF) / 255
            a = Double(value & 0xFF) / 255
        default:
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
            a = 1
        }
        self.init(red: r, green: g, blue: b, opacity: a)
    }
}

extension Color {
    /// Base app background. Near-black so glass and thermal effects have contrast to read against.
    static let dsCanvas = Color(hex: "#0A0A0C")

    /// Hot center of Thermal Glow on contact. Transient only — never a static fill (DESIGN.md "No Flat Glow Rule").
    static let dsThermalCore = Color(hex: "#FF3B30")

    /// Outer edge of the Thermal Glow gradient; blend with `.plusLighter` to combine additively with dsThermalCore.
    static let dsThermalCorona = Color(hex: "#FF9500")

    /// Glass surface tint. Always paired with `.ultraThinMaterial` — this color alone is not the material.
    static let dsGlassSurface = Color(hex: "#FFFFFF0D")

    /// Hairline edge on glass surfaces (pair with a ~0.5pt stroke).
    static let dsGlassBorder = Color(hex: "#FFFFFF33")

    /// Primary text on the dark canvas.
    static let dsInkPrimary = Color(hex: "#F5F5F7")

    /// Secondary/supporting text — labels, metadata, timestamps.
    static let dsInkSecondary = Color(hex: "#98989F")
}
