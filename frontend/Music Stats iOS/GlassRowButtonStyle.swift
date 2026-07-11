// GlassRowButtonStyle.swift
//
// Press feedback for GlassListRow-based buttons (Top Songs/Albums/Artists rows).
// These previously used PlainButtonStyle, which gives zero visual response to a
// tap — a real gap against DESIGN.md's "Physicality of feedback" principle on
// the app's primary interaction surface.

import SwiftUI

struct GlassRowButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassRowButtonStyle {
    static var glassRow: GlassRowButtonStyle { GlassRowButtonStyle() }
}
