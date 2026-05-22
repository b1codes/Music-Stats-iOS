import Testing
import SwiftUI
@testable import Music_Stats_iOS

struct BlurIntensityTests {
    @Test func testBlurIntensityValues() {
        #expect(BlurIntensity.none.rawValue == 0)
        #expect(BlurIntensity.subtle.rawValue == 3)
        #expect(BlurIntensity.standard.rawValue == 5)
        #expect(BlurIntensity.strong.rawValue == 10)
    }
    
    @Test func testBlurIntensityDisplayNames() {
        #expect(BlurIntensity.none.displayName == "None")
        #expect(BlurIntensity.standard.displayName == "Default")
    }
}
