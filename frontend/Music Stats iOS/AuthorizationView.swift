//
//  AuthorizationView.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 11/2/23.
//

import SwiftUI

struct AuthorizationView: View {

    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        VStack(spacing: 24) {
            Image("AppIcon")
                .resizable()
                .cornerRadius(.dsRoundedMD)
                .scaledToFill()
                .frame(width: 200, height: 200)

            Text("Music Stats")
                .font(.largeTitle)
                .bold()

            Text("Sign in to get started")
                .foregroundColor(.dsInkSecondary)

            Button("Sign In") {
                authManager.login()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

#Preview {
    AuthorizationView()
        .environmentObject(AuthManager())
}
