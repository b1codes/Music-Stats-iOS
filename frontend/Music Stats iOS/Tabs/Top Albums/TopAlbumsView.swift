// TopAlbumsView.swift

import SwiftUI

struct TopAlbumsView: View {
    @ObservedObject var userTopItems: UserTopItems
    @State private var selection: Int = 0
    @State private var selectedAlbum: Album?

    var body: some View {
        NavigationStack {
            StateContainerView(
                state: resolvedState,
                loadingLabel: "Calculating Top Albums…",
                emptySymbol: "music.note.list",
                emptyTitle: "No Top Albums Found",
                emptyDescription: "We rank albums based on how many of your top 50 songs are from the same album. " +
                                  "Listen to more songs from the same album to see them here!",
                onRetry: { userTopItems.retry() }
            ) {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(albumsForSelection() ?? []) { album in
                            Button {
                                selectedAlbum = album
                            } label: {
                                AlbumCard(album: album)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .id(album.id)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }
                .id(selection)
            }
            .navigationDestination(item: $selectedAlbum) { album in
                AlbumDetailView(albumData: album)
            }
            .navigationTitle("Top Albums")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                timeframeToolbar
                ProfileToolbarItem()
            }
        }
    }

    private var resolvedState: ViewState {
        guard userTopItems.fetchState == .content else { return userTopItems.fetchState }
        let albums = albumsForSelection() ?? []
        return albums.isEmpty ? .empty : .content
    }

    private var timeframeToolbar: some ToolbarContent {
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
    }

    private func albumsForSelection() -> [Album]? {
        switch selection {
        case 0: return userTopItems.topAlbumsList["short"]
        case 1: return userTopItems.topAlbumsList["medium"]
        case 2: return userTopItems.topAlbumsList["long"]
        default: return nil
        }
    }
}

struct TopAlbumsView_Previews: PreviewProvider {
    static var previews: some View {
        TopAlbumsView(userTopItems: UserTopItems())
    }
}
