//
//  TabUIView.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 10/24/23.
//

import SwiftUI
import Foundation

struct TabUIView: View {

    @EnvironmentObject var authManager: AuthManager
    @StateObject private var userTopItems = UserTopItems()

    var body: some View {
        TabView {
            if let accessToken = authManager.accessToken, let tokenType = authManager.tokenType {
                TopSongsView(userTopItems: userTopItems)
                    .tabItem {
                        Image(systemName: "music.note")
                        Text("Top Songs")
                    }
                TopAlbumsView(userTopItems: userTopItems)
                    .tabItem {
                        Image(systemName: "square.stack")
                        Text("Top Albums")
                    }
                TopArtistsView(userTopItems: userTopItems)
                    .tabItem {
                        Image(systemName: "music.mic")
                        Text("Top Artists")
                    }

                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text("Settings")
                    }
            } else {
                ProgressView()
            }
        }
        .environmentObject(userTopItems)
        .task {
            if let accessToken = authManager.accessToken,
               let tokenType = authManager.tokenType {
                userTopItems.accessToken = accessToken
                userTopItems.tokenType = tokenType
                async let profile: Void = userTopItems.getUserProfile()
                async let data: Void = userTopItems.fetchAll()
                await profile
                await data
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
