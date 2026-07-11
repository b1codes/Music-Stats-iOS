// GlassListRow.swift
//
// Shared row for the Top Songs / Top Albums / Top Artists lists: rank, artwork,
// title, optional subtitle, chevron, on a Glass Surface card. Extracted from
// SongCard/AlbumCard/ArtistCard, which had identical structure apart from
// which model fields feed the row.

import SwiftUI

struct GlassListRow: View {
    @Environment(\.cardBlur) var cardBlur
    let rank: Int
    let title: String
    let subtitle: String?
    let imageURL: URL?
    let accessibilityLabel: String

    var body: some View {
        // Load the artwork once; reuse the decoded image for both the thumbnail
        // and the blurred background instead of fetching the same URL twice.
        AsyncImage(url: imageURL) { phase in
            content(artwork: phase.image)
        }
    }

    @ViewBuilder
    private func content(artwork: Image?) -> some View {
        HStack(alignment: .center) {
            // 1. Rank
            Text(String(rank))
                .bold()
                .frame(width: 30, alignment: .leading)
                .padding(.leading)

            // 2. Artwork
            Group {
                if let artwork {
                    artwork.resizable()
                } else {
                    ProgressView()
                }
            }
            .frame(width: 80, height: 80)
            .cornerRadius(.dsRoundedSM)
            .padding(.vertical, 10)

            // 3. Title and Subtitle
            VStack(alignment: .leading) {
                Text(title)
                    .bold()
                    .lineLimit(2)
                if let subtitle {
                    Text(subtitle)
                        .lineLimit(1)
                        .foregroundColor(.dsInkSecondary)
                }
            }
            .padding(.trailing)

            Spacer()

            // 4. Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.dsInkSecondary)
                .padding(.trailing)
                .accessibilityHidden(true)
        }
        .background(
            ZStack {
                // Same decoded image as the thumbnail, blurred — no second fetch.
                if let artwork {
                    artwork
                        .resizable()
                        .scaledToFill()
                        .blur(radius: cardBlur)
                }

                Rectangle()
                    .foregroundColor(.dsCanvas.opacity(0.6))
            }
            .clipped()
        )
        .cornerRadius(.dsRoundedMD)
        .overlay(
            RoundedRectangle(cornerRadius: .dsRoundedMD)
                .stroke(Color.dsGlassBorder, lineWidth: 0.5)
        )
        .contentShape(Rectangle())
        // Cap Dynamic Type growth in this dense, fixed-thumbnail row so extreme
        // accessibility sizes don't crush the title to a sliver; detail screens
        // (which have room to scroll) are left uncapped.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
}
