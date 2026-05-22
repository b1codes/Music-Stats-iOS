// TopArtistsView.swift

import SwiftUI

struct TopArtistsView: View {
    @ObservedObject var userTopItems: UserTopItems
    @State private var selection: Int = 0
    @State private var selectedArtist: Artist?

    var body: some View {
        NavigationStack {
            StateContainerView(
                state: userTopItems.fetchState,
                loadingLabel: "Loading Artists…",
                emptySymbol: "music.mic",
                emptyTitle: "No Top Artists Found",
                emptyDescription: "",
                onRetry: { userTopItems.retry() }
            ) {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(artistsForSelection() ?? []) { artist in
                            Button {
                                selectedArtist = artist
                            } label: {
                                ArtistCard(artist: artist)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .id(artist.id)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }
                .id(selection)
            }
            .navigationDestination(item: $selectedArtist) { artist in
                ArtistDetailView(spotifyId: artist.spotifyId, rank: artist.rank)
            }
            .navigationTitle("Top Artists")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Time Period", selection: $selection) {
                            Text("Past Month").tag(0)
                            Text("Past 6 Months").tag(1)
                            Text("Past Years").tag(2)
                        }
                    } label: {
                        Image(systemName: "calendar")
                    }
                }
                ProfileToolbarItem()
            }
        }
    }

    private func artistsForSelection() -> [Artist]? {
        switch selection {
        case 0: return userTopItems.topArtistsList["short"]
        case 1: return userTopItems.topArtistsList["medium"]
        case 2: return userTopItems.topArtistsList["long"]
        default: return nil
        }
    }
}
