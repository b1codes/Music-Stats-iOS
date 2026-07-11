// GlassButtonStyle.swift
//
// Shared Glass Surface button chrome, per DESIGN.md's Buttons spec. Extracted
// from the "Open in Spotify" buttons in Song/Album/ArtistDetailView, which
// repeated the same modifier chain identically.

import SwiftUI

struct GlassButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .foregroundColor(.dsInkPrimary)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .background(Color.dsGlassSurface)
            .overlay(
                RoundedRectangle(cornerRadius: .dsRoundedSM)
                    .stroke(Color.dsGlassBorder, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: .dsRoundedSM))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassButtonStyle {
    static var glass: GlassButtonStyle { GlassButtonStyle() }
}
