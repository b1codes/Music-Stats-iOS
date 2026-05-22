// ArtistDetailView.swift

import SwiftUI

struct ArtistDetailView: View {
    @EnvironmentObject var userTopItems: UserTopItems
    let spotifyId: String
    let rank: Int?

    @State private var artist: ArtistResponse?
    @State private var isLoading = true

    private func genresToString(genres: [String]?) -> String {
        return genres?.joined(separator: ", ") ?? "N/A"
    }

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Fetching Artist Details...")
                    .padding(.top, 50)
            } else if let artist = artist {
                VStack(alignment: .leading, spacing: 20) {
                    AsyncImage(url: URL(string: artist.images?.first?.url ?? "")) { image in
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

                    Text(artist.name)
                        .font(.largeTitle)
                        .bold()

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        if let genres = artist.genres, !genres.isEmpty {
                            DetailRow(label: "Genres", value: genresToString(genres: genres))
                        }
                        if let popularity = artist.popularity {
                            DetailRow(label: "Popularity", value: "\(popularity)/100")
                        }
                        if let rank = rank {
                            DetailRow(label: "Rank", value: "#\(rank)")
                        }
                    }
                    .padding(.top, 10)

                    Button("Open in Spotify") {
                        if let url = URL(string: "https://open.spotify.com/artist/\(spotifyId)") {
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
                Text("Failed to load artist details.")
                    .foregroundColor(.secondary)
                    .padding(.top, 50)
            }
        }
        .navigationTitle("Artist Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                artist = try await userTopItems.getArtist(id: spotifyId)
            } catch {
                // artist remains nil; view shows "Failed to load artist details."
            }
            isLoading = false
        }
    }
}

struct ArtistDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ArtistDetailView(spotifyId: "testId", rank: 1)
            .environmentObject(UserTopItems())
    }
}
