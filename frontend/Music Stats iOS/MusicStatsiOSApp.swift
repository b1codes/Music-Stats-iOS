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
                    ProgressView("Signing in...")
                } else if !authManager.isAuth0Authenticated {
                    AuthorizationView()
                } else if !authManager.isAuthenticated {
                    SpotifyConnectionView()
                } else {
                    TabUIView()
                        .environment(\.cardBlur, CGFloat(blurIntensity))
                }
            }
            .environmentObject(authManager)
        }
    }
}
