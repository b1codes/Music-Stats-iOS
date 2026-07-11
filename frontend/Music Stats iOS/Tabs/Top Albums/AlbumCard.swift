// AlbumCard.swift

import SwiftUI

struct AlbumCard: View {
    var album: Album

    private func artistsToString() -> String {
        return album.artists?.map { $0.name }.joined(separator: ", ") ?? ""
    }

    var body: some View {
        GlassListRow(
            rank: album.rank ?? 0,
            title: album.name,
            subtitle: artistsToString(),
            imageURL: URL(string: album.images.first?.url ?? ""),
            accessibilityLabel: "Rank \(album.rank ?? 0), \(album.name) by \(artistsToString())"
        )
    }
}
