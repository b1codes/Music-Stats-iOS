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
                            .foregroundColor(.gray.opacity(0.3))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(ProgressView())
                    }
                    .cornerRadius(15)
                    .shadow(radius: 10)
                    .padding(.bottom, 10)

                    Text(song.name)
                        .font(.largeTitle)
                        .bold()

                    Text(artistsToString(artists: song.artists))
                        .font(.title2)
                        .foregroundColor(.secondary)

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

                    Button("Open in Spotify") {
                        if let url = URL(string: "https://open.spotify.com/track/\(spotifyId)") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.spotifyGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    Spacer()
                }
                .padding()
            } else {
                Text("Failed to load track details.")
                    .foregroundColor(.secondary)
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
