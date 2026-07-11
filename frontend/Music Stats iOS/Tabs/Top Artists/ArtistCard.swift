// ArtistCard.swift

import SwiftUI

struct ArtistCard: View {
    var artist: Artist

    var body: some View {
        GlassListRow(
            rank: artist.rank ?? 0,
            title: artist.name,
            subtitle: nil,
            imageURL: URL(string: artist.images?.first?.url ?? ""),
            accessibilityLabel: "Rank \(artist.rank ?? 0), \(artist.name)"
        )
    }
}
