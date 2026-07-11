// SongDetailView.swift

import SwiftUI

struct SongDetailView: View {
    @EnvironmentObject var userTopItems: UserTopItems
    let spotifyId: String
    let rank: Int?

    @State private var song: SongResponse?
    @State private var isLoading = true

    private func artistsToString(artists: [ArtistResponse]) -> String {
        return artists.map { $0.name }.joined(separator: ", ")
    }

    private func formatDuration(ms duration: Int) -> String {
        let totalSeconds = duration / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Fetching Track Details...")
                    .padding(.top, 50)
            } else if let song = song {
                VStack(alignment: .leading, spacing: 20) {
                    AsyncImage(url: URL(string: song.album.images.first?.url ?? "")) { image in
                        image.resizable()
                            .scaledToFit()
                    } placeholder: {
                        Rectangle()
                            .foregroundColor(.dsGlassSurface)
                            .background(.ultraThinMaterial)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(ProgressView())
                    }
                    .cornerRadius(.dsRoundedMD)
                    .padding(.bottom, 10)

                    Text(song.name)
                        .font(.largeTitle)
                        .bold()

                    Text(artistsToString(artists: song.artists))
                        .font(.title2)
                        .foregroundColor(.dsInkSecondary)

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: "Album", value: song.album.name)
                        DetailRow(label: "Release Date", value: song.album.releaseDate)
                        DetailRow(label: "Duration", value: formatDuration(ms: song.durationMs))
                        DetailRow(label: "Popularity", value: "\(song.popularity)/100")
                        if let rank = rank {
                            DetailRow(label: "Rank", value: "#\(rank)")
                        }
                    }
                    .padding(.top, 10)

                    Button {
                        if let url = URL(string: "https://open.spotify.com/track/\(spotifyId)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Open in Spotify")
                    }
                    .buttonStyle(.glass)
                    .padding(.top, 8)

                    Spacer()
                }
                .padding()
            } else {
                Text("Failed to load track details.")
                    .foregroundColor(.dsInkSecondary)
                    .padding(.top, 50)
            }
        }
        .navigationTitle("Song Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                song = try await userTopItems.getTrack(id: spotifyId)
            } catch {
                // song remains nil; view shows "Failed to load track details."
            }
            isLoading = false
        }
    }
}

struct SongDetailView_Previews: PreviewProvider {
    static var previews: some View {
        SongDetailView(spotifyId: "testId", rank: 1)
            .environmentObject(UserTopItems())
    }
}
