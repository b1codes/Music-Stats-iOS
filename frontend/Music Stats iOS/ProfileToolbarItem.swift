// ProfileToolbarItem.swift

import SwiftUI

struct ProfileToolbarItem: ToolbarContent {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var userTopItems: UserTopItems

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                if let profile = userTopItems.userProfile {
                    Section {
                        Text("Name: \(profile.displayName ?? "No Name")")
                        if let email = profile.email {
                            Text("Email: \(email)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Button(role: .destructive) {
                    userTopItems.reset()
                    authManager.logout()
                } label: {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                if let profile = userTopItems.userProfile,
                   let imageUrlString = profile.images?.first?.url,
                   let imageUrl = URL(string: imageUrlString) {
                    AsyncImage(url: imageUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.gray)
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}
