// AlbumDetailView.swift

import SwiftUI

struct AlbumDetailView: View {
    @EnvironmentObject var userTopItems: UserTopItems
    let albumData: Album

    @State private var albumResponse: AlbumResponse?
    @State private var isLoading = true

    private func artistsToString(artists: [ArtistResponse]?) -> String {
        return artists?.map { $0.name }.joined(separator: ", ") ?? "Unknown Artist"
    }

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Fetching Album Details...")
                    .padding(.top, 50)
            } else if let albumResponse = albumResponse {
                VStack(alignment: .leading, spacing: 20) {
                    AsyncImage(url: URL(string: albumResponse.images.first?.url ?? "")) { image in
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

                    Text(albumResponse.name)
                        .font(.largeTitle)
                        .bold()

                    Text(artistsToString(artists: albumResponse.artists))
                        .font(.title2)
                        .foregroundColor(.secondary)

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: "Release Date", value: albumResponse.releaseDate)
                        if let totalTracks = albumResponse.totalTracks {
                            DetailRow(label: "Total Tracks", value: "\(totalTracks)")
                        }
                        if let label = albumResponse.label {
                            DetailRow(label: "Label", value: label)
                        }
                        if let popularity = albumResponse.popularity {
                            DetailRow(label: "Popularity", value: "\(popularity)/100")
                        }
                        if let songCount = albumData.songCount {
                            DetailRow(label: "Songs in Your Top 50", value: "\(songCount)")
                        }
                        if let rank = albumData.rank {
                            DetailRow(label: "Rank", value: "#\(rank)")
                        }
                    }
                    .padding(.top, 10)

                    Button {
                        if let url = URL(string: "https://open.spotify.com/album/\(albumData.spotifyId ?? "")") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up.forward.app")
                            Text("Open in Spotify")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.spotifyGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    if let contributingSongs = albumData.contributingSongs, !contributingSongs.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Top Songs from this Album")
                                .font(.title2)
                                .bold()
                                .padding(.top, 20)

                            LazyVStack(spacing: 12) {
                                ForEach(contributingSongs) { song in
                                    NavigationLink(destination: SongDetailView(spotifyId: song.spotifyId, rank: song.rank)) {
                                        SongCard(song: song)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }

                    Spacer()
                }
                .padding()
            } else {
                Text("Failed to load album details.")
                    .foregroundColor(.secondary)
                    .padding(.top, 50)
            }
        }
        .navigationTitle("Album Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                albumResponse = try await userTopItems.getAlbum(id: albumData.spotifyId ?? "")
            } catch {
                // albumResponse remains nil; view shows "Failed to load album details."
            }
            isLoading = false
        }
    }
}
