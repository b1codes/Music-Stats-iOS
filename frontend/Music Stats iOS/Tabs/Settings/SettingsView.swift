import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var userTopItems: UserTopItems
    @AppStorage("cardBlurIntensity") private var blurIntensity: Int = BlurIntensity.standard.rawValue

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    if let profile = userTopItems.userProfile {
                        HStack {
                            AsyncImage(url: URL(string: profile.images?.first?.url ?? "")) { image in
                                image.resizable()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading) {
                                Text(profile.displayName ?? "Unknown User")
                                    .font(.headline)
                                Text(profile.email ?? "No email provided")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button(role: .destructive) {
                        authManager.logout()
                        userTopItems.reset()
                    } label: {
                        Text("Log Out")
                    }
                }
                
                Section("Appearance") {
                    Picker("Card Blur Intensity", selection: $blurIntensity) {
                        ForEach(BlurIntensity.allCases) { intensity in
                            Text(intensity.displayName).tag(intensity.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
