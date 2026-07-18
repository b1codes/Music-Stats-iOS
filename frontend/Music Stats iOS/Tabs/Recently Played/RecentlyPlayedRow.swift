// RecentlyPlayedRow.swift
// Music Stats iOS
//
// A custom list row layout for recently played tracks showing the relative timestamp.

import SwiftUI

struct RecentlyPlayedRow: View {
    @Environment(\.cardBlur) var cardBlur
    let record: PlayRecord
    
    private func artistsToString() -> String {
        return record.artists.map { $0.name }.joined(separator: ", ")
    }
    
    var body: some View {
        AsyncImage(url: URL(string: record.album.images.first?.url ?? "")) { phase in
            content(artwork: phase.image)
        }
    }
    
    @ViewBuilder
    private func content(artwork: Image?) -> some View {
        HStack(alignment: .center) {
            // 1. Artwork
            Group {
                if let artwork {
                    artwork.resizable()
                } else {
                    ProgressView()
                }
            }
            .frame(width: 80, height: 80)
            .cornerRadius(.dsRoundedSM)
            .padding(.leading)
            .padding(.vertical, 10)
            
            // 2. Title and Subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(record.name)
                    .font(.body)
                    .bold()
                    .lineLimit(2)
                    .foregroundColor(.dsInkPrimary)
                
                Text(artistsToString())
                    .font(.subheadline)
                    .lineLimit(1)
                    .foregroundColor(.dsInkSecondary)
            }
            .padding(.leading, 8)
            
            Spacer()
            
            // 3. Played At Relative Timestamp
            Text(record.relativeTime)
                .font(.footnote)
                .foregroundColor(.dsInkSecondary)
                .padding(.trailing)
        }
        .background(
            ZStack {
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
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Played \(record.relativeTime), \(record.name) by \(artistsToString())")
    }
}
