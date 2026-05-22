// SongCard.swift

import SwiftUI

struct SongCard: View {
    @Environment(\.cardBlur) var cardBlur
    var song: Song

    // This helper function is now more efficient and safer.
    private func artistsToString() -> String {
        return song.artists.map { $0.name }.joined(separator: ", ")
    }

    var body: some View {
        // The main view is now the content HStack. Its size will determine the card's size.
        HStack(alignment: .center) {
            // 1. Rank
            Text(String(song.rank ?? 0))
                .bold()
                .frame(width: 30, alignment: .leading)
                .padding(.leading)

            // 2. Album Cover
            AsyncImage(url: URL(string: song.album.images.first?.url ?? "")) { image in
                image.resizable()
            } placeholder: {
                ProgressView()
            }
            // Use a fixed frame for the image. Padding on this element will define the card's height.
            .frame(width: 80, height: 80)
            .cornerRadius(10.0)
            .padding(.vertical, 10)

            // 3. Song Title and Artists
            VStack(alignment: .leading) {
                Text(song.name)
                    .bold()
                    .lineLimit(1)
                Text(artistsToString())
                    .lineLimit(1)
            }
            .padding(.trailing)

            Spacer()

            // 4. Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.trailing)
        }
        // The background is now a modifier. It sizes itself automatically to the HStack above.
        .background(
            ZStack {
                // Background blurred image
                AsyncImage(url: URL(string: song.album.images.first?.url ?? "")) { image in
                    image.resizable()
                } placeholder: {
                    Color.clear
                }
                .scaledToFill()
                .blur(radius: cardBlur)

                // Overlay
                Rectangle()
                    .foregroundColor(.gray.opacity(0.6))
            }
            .clipped()
        )
        // Clip the entire view (including the background) to have rounded corners.
        .cornerRadius(15.0)
        .contentShape(Rectangle())
    }
}
