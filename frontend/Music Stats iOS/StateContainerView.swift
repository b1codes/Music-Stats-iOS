// StateContainerView.swift

import SwiftUI

struct StateContainerView<Content: View>: View {
    let state: ViewState
    let loadingLabel: String
    let emptySymbol: String
    let emptyTitle: String
    let emptyDescription: String
    let onRetry: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        switch state {
        case .loading:
            VStack {
                ProgressView(loadingLabel)
            }
        case .content:
            content()
        case .error:
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                Text("Something went wrong")
                    .font(.title2)
                    .bold()
                Button("Tap to Retry", action: onRetry)
                    .buttonStyle(.bordered)
            }
            .padding()
        case .empty:
            VStack(spacing: 20) {
                Image(systemName: emptySymbol)
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                Text(emptyTitle)
                    .font(.title2)
                    .bold()
                Text(emptyDescription)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
            }
            .padding()
        }
    }
}

#Preview("Loading") {
    StateContainerView(
        state: .loading,
        loadingLabel: "Loading Songs…",
        emptySymbol: "music.note",
        emptyTitle: "No Songs Found",
        emptyDescription: "",
        onRetry: {}
    ) {
        Text("Content goes here")
    }
}

#Preview("Content") {
    StateContainerView(
        state: .content,
        loadingLabel: "Loading Songs…",
        emptySymbol: "music.note",
        emptyTitle: "No Songs Found",
        emptyDescription: "",
        onRetry: {}
    ) {
        Text("Content goes here")
            .font(.title)
    }
}

#Preview("Error") {
    StateContainerView(
        state: .error,
        loadingLabel: "Loading Songs…",
        emptySymbol: "music.note",
        emptyTitle: "No Songs Found",
        emptyDescription: "",
        onRetry: {}
    ) {
        Text("Content goes here")
    }
}

#Preview("Empty") {
    StateContainerView(
        state: .empty,
        loadingLabel: "Loading Songs…",
        emptySymbol: "music.note.list",
        emptyTitle: "No Top Albums Found",
        emptyDescription: "We rank albums based on how many of your top 50 songs are from the same album. Listen to more songs from the same album to see them here!",
        onRetry: {}
    ) {
        Text("Content goes here")
    }
}
