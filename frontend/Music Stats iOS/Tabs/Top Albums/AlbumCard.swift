// AlbumCard.swift

import SwiftUI

struct AlbumCard: View {
    @Environment(\.cardBlur) var cardBlur
    var album: Album

    private func artistsToString() -> String {
        return album.artists?.map { $0.name }.joined(separator: ", ") ?? ""
    }

    var body: some View {
        HStack(alignment: .center) {
            // 1. Rank
            Text(String(album.rank ?? 0))
                .bold()
                .frame(width: 30, alignment: .leading)
                .padding(.leading)

            // 2. Album Cover
            AsyncImage(url: URL(string: album.images.first?.url ?? "")) { image in
                image.resizable()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 80, height: 80)
            .cornerRadius(10.0)
            .padding(.vertical, 10)

            // 3. Album Title and Artist
            VStack(alignment: .leading) {
                Text(album.name)
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
        .background(
            ZStack {
                // Background blurred image
                AsyncImage(url: URL(string: album.images.first?.url ?? "")) { image in
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
        .cornerRadius(15.0)
        .contentShape(Rectangle())
    }
}
