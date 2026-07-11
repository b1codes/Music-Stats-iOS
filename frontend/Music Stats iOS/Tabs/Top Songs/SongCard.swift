// SongCard.swift

import SwiftUI

struct SongCard: View {
    var song: Song

    private func artistsToString() -> String {
        return song.artists.map { $0.name }.joined(separator: ", ")
    }

    var body: some View {
        GlassListRow(
            rank: song.rank ?? 0,
            title: song.name,
            subtitle: artistsToString(),
            imageURL: URL(string: song.album.images.first?.url ?? ""),
            accessibilityLabel: "Rank \(song.rank ?? 0), \(song.name) by \(artistsToString())"
        )
    }
}
