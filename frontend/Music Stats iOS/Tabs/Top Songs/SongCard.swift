// SongCard.swift

import SwiftUI

struct SongCard: View {
    @EnvironmentObject var userTopItems: UserTopItems
    var song: Song

    private func artistsToString() -> String {
        return song.artists.map { $0.name }.joined(separator: ", ")
    }

    private var isSongRecent: Bool {
        // A song is recent if it was played within the last 12 hours
        let twelveHoursAgo = Date().addingTimeInterval(-43200)
        return userTopItems.recentlyPlayedList.contains { record in
            record.spotifyId == song.spotifyId && record.playedAt >= twelveHoursAgo
        }
    }

    var body: some View {
        GlassListRow(
            rank: song.rank ?? 0,
            title: song.name,
            subtitle: artistsToString(),
            imageURL: URL(string: song.album.images.first?.url ?? ""),
            accessibilityLabel: "Rank \(song.rank ?? 0), \(song.name) by \(artistsToString())",
            isRecent: isSongRecent
        )
    }
}
