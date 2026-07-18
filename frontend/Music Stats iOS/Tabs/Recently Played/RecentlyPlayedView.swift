// RecentlyPlayedView.swift
// Music Stats iOS
//
// The UI for the new tab displaying the recently played tracks list.

import SwiftUI

struct RecentlyPlayedView: View {
    @ObservedObject var userTopItems: UserTopItems
    @State private var selectedRecord: PlayRecord?

    var body: some View {
        NavigationStack {
            StateContainerView(
                state: userTopItems.fetchState,
                loadingLabel: "Loading Playback History…",
                emptySymbol: "clock.arrow.circlepath",
                emptyTitle: "No Playback History",
                emptyDescription: "We couldn't find any recently played songs. Listen to music on Spotify and check back.",
                onRetry: { userTopItems.retry() }
            ) {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(userTopItems.recentlyPlayedList) { record in
                            Button {
                                selectedRecord = record
                            } label: {
                                RecentlyPlayedRow(record: record)
                            }
                            .buttonStyle(.glassRow)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }
                .refreshable {
                    try? await userTopItems.getRecentlyPlayed()
                }
            }
            .navigationDestination(item: $selectedRecord) { record in
                SongDetailView(spotifyId: record.spotifyId, rank: nil)
            }
            .navigationTitle("Recently Played")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ProfileToolbarItem()
            }
        }
    }
}
