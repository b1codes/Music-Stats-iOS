// ArtistCard.swift

import SwiftUI

struct ArtistCard: View {
    @Environment(\.cardBlur) var cardBlur
    var artist: Artist

    var body: some View {
        // The structure mirrors the new SongCard.
        HStack(alignment: .center) {
            // 1. Rank
            Text(String(artist.rank ?? 0))
                .bold()
                .frame(width: 30, alignment: .leading)
                .padding(.leading)

            // 2. Artist Image
            AsyncImage(url: URL(string: artist.images?.first?.url ?? "")) { image in
                image.resizable()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 80, height: 80)
            .cornerRadius(10.0)
            .padding(.vertical, 10)

            // 3. Artist Name
            VStack(alignment: .leading) {
                Text(artist.name)
                    .bold()
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
        // The same background modifier technique is used here.
        .background(
            ZStack {
                // Background blurred image
                AsyncImage(url: URL(string: artist.images?.first?.url ?? "")) { image in
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
