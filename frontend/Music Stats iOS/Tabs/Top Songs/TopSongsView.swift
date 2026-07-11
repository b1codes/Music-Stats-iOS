// TopSongsView.swift

import SwiftUI

struct TopSongsView: View {
    @ObservedObject var userTopItems: UserTopItems
    @State private var selection: Int = 0
    @State private var selectedSong: Song?

    var body: some View {
        NavigationStack {
            StateContainerView(
                state: userTopItems.fetchState,
                loadingLabel: "Loading Songs…",
                emptySymbol: "music.note",
                emptyTitle: "No Top Songs Found",
                emptyDescription: "We couldn't find any top songs for this time period. " +
                                  "Listen to more music on Spotify to see your top tracks here.",
                onRetry: { userTopItems.retry() }
            ) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(songsForSelection() ?? []) { song in
                                Button {
                                    selectedSong = song
                                } label: {
                                    SongCard(song: song)
                                }
                                .buttonStyle(.glassRow)
                                .id(song.id)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                    }
                    // Scroll back to the top on a timeframe switch without tearing down
                    // and re-fetching every row's artwork (see ForEach's own .id(song.id)).
                    .onChange(of: selection) { _, _ in
                        if let firstID = songsForSelection()?.first?.id {
                            proxy.scrollTo(firstID, anchor: .top)
                        }
                    }
                }
            }
            .navigationDestination(item: $selectedSong) { song in
                SongDetailView(spotifyId: song.spotifyId, rank: song.rank)
            }
            .navigationTitle("Top Songs")
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

    private func songsForSelection() -> [Song]? {
        switch selection {
        case 0: return userTopItems.topSongsList["short"]
        case 1: return userTopItems.topSongsList["medium"]
        case 2: return userTopItems.topSongsList["long"]
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
