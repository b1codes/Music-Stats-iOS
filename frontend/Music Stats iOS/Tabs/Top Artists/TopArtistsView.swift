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
                emptyDescription: "We couldn't find any top artists for this time period. " +
                                  "Listen to more music on Spotify to see your top artists here.",
                onRetry: { userTopItems.retry() }
            ) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(artistsForSelection() ?? []) { artist in
                                Button {
                                    selectedArtist = artist
                                } label: {
                                    ArtistCard(artist: artist)
                                }
                                .buttonStyle(.glassRow)
                                .id(artist.id)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                    }
                    // Scroll back to the top on a timeframe switch without tearing down
                    // and re-fetching every row's artwork (see ForEach's own .id(artist.id)).
                    .onChange(of: selection) { _, _ in
                        if let firstID = artistsForSelection()?.first?.id {
                            proxy.scrollTo(firstID, anchor: .top)
                        }
                    }
                }
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
                    .accessibilityLabel("Time Period: \(timeframeLabel)")
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

    private var timeframeLabel: String {
        switch selection {
        case 0: return "Past Month"
        case 1: return "Past 6 Months"
        default: return "Past Years"
        }
    }
}
