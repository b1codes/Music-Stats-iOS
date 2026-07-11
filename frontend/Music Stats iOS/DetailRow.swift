// DetailRow.swift

import SwiftUI

struct DetailRow: View {
    var label: String
    var value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.dsInkSecondary)
                .bold()
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }
}
