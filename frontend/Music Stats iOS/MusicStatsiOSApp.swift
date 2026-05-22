//
//  MusicStatsiOSApp.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 10/23/23.
//

import SwiftUI
import Foundation

@main
struct MusicStatsiOSApp: App {

    @StateObject private var authManager = AuthManager()
    @AppStorage("cardBlurIntensity") private var blurIntensity: Int = BlurIntensity.standard.rawValue

    var body: some Scene {
        WindowGroup {
            ZStack {
                if authManager.isLoading {
                    ProgressView("Logging in...")
                } else if authManager.isAuthenticated {
                    TabUIView()
                        .environment(\.cardBlur, CGFloat(blurIntensity))
                } else {
                    AuthorizationView()
                }
            }
            .environmentObject(authManager)
        }
    }
}
