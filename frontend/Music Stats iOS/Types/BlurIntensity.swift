import Foundation

enum BlurIntensity: Int, CaseIterable, Identifiable {
    case none = 0
    case subtle = 3
    case standard = 5
    case strong = 10
    
    var id: Int { self.rawValue }
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .subtle: return "Subtle"
        case .standard: return "Default"
        case .strong: return "Strong"
        }
    }
}
