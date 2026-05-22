import SwiftUI

struct CardBlurKey: EnvironmentKey {
    static let defaultValue: CGFloat = 5
}

extension EnvironmentValues {
    var cardBlur: CGFloat {
        get { self[CardBlurKey.self] }
        set { self[CardBlurKey.self] = newValue }
    }
}
