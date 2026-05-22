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
                emptyDescription: "",
                onRetry: { userTopItems.retry() }
            ) {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(songsForSelection() ?? []) { song in
                            Button {
                                selectedSong = song
                            } label: {
                                SongCard(song: song)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .id(song.id)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }
                .id(selection)
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
}
