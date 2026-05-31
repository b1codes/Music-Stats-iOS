//
//  AuthManager.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 8/1/25.
//

import Auth0
import Foundation
import KeychainSwift

@MainActor
class AuthManager: ObservableObject {

    @Published var isAuth0Authenticated: Bool = false
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = true

    // CSRF state token for Spotify OAuth
    var authState: String?

    // Spotify tokens used directly against the Spotify API
    var accessToken: String?
    var tokenType: String?

    private let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
    private var keychain = KeychainSwift()

    init() {
        restoreSession()
    }

    // MARK: - Session Restoration

    private func restoreSession() {
        Task {
            guard credentialsManager.canRenew() else {
                isLoading = false
                return
            }
            do {
                _ = try await credentialsManager.credentials()
                isAuth0Authenticated = true
                restoreSpotifyTokens()
            } catch {
                _ = credentialsManager.clear()
            }
            isLoading = false
        }
    }

    private func restoreSpotifyTokens() {
        guard let token = keychain.get("spotifyAccessToken"),
              let type = keychain.get("spotifyTokenType"),
              keychain.get("spotifyRefreshToken") != nil else { return }
        accessToken = token
        tokenType = type
        isAuthenticated = true
    }

    // MARK: - Auth0 Login / Logout

    func login() {
        let audience = Bundle.main.object(forInfoDictionaryKey: "Auth0Audience") as? String ?? ""
        Auth0
            .webAuth()
            .audience(audience)
            .start { [weak self] result in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    switch result {
                    case .success(let credentials):
                        _ = self.credentialsManager.store(credentials: credentials) // Bool result intentionally discarded
                        self.isAuth0Authenticated = true
                        self.notifyBackend(accessToken: credentials.accessToken)
                    case .failure(let error):
                        print("Auth0 login failed: \(error.localizedDescription)")
                    }
                }
            }
    }

    func logout() {
        Auth0.webAuth().clearSession { _ in }
        _ = credentialsManager.clear()
        keychain.clear()
        accessToken = nil
        tokenType = nil
        isAuth0Authenticated = false
        isAuthenticated = false
    }

    // Registers the user with our backend after Auth0 login.
    private func notifyBackend(accessToken: String) {
        Task {
            guard let url = backendURL(path: "/auth/login") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            _ = try? await URLSession.shared.data(for: request)
        }
    }

    // MARK: - Spotify Connection

    func getSpotifyAuthorizationURL() -> String {
        let state = generateRandomString(length: 16)
        self.authState = state

        var components = URLComponents()
        components.scheme = "https"
        components.host = "accounts.spotify.com"
        components.path = "/authorize"

        let spotifyClientID = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_API_CLIENT_ID") as? String
        let redirectURIHost = Bundle.main.object(forInfoDictionaryKey: "REDIRECT_URI_HOST") as? String
        let redirectURIScheme = Bundle.main.object(forInfoDictionaryKey: "REDIRECT_URI_SCHEME") as? String
        let redirectURI = "\(redirectURIScheme ?? "")://\(redirectURIHost ?? "")"

        components.queryItems = [
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "scope", value: "user-read-private user-read-email user-top-read"),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "client_id", value: spotifyClientID),
        ]
        return components.string ?? ""
    }

    func connectSpotify(with code: String) {
        isLoading = true
        Task { await exchangeSpotifyCode(code: code) }
    }

    private func exchangeSpotifyCode(code: String) async {
        let redirectURIHost = Bundle.main.object(forInfoDictionaryKey: "REDIRECT_URI_HOST") as? String
        let redirectURIScheme = Bundle.main.object(forInfoDictionaryKey: "REDIRECT_URI_SCHEME") as? String
        let redirectURI = "\(redirectURIScheme ?? "")://\(redirectURIHost ?? "")"

        guard let url = backendURL(path: "/token") else {
            isLoading = false
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["code": code, "redirect_uri": redirectURI])
        await performSpotifyTokenRequest(request)
    }

    func refreshSpotifyToken() async {
        guard let refreshToken = keychain.get("spotifyRefreshToken"),
              let url = backendURL(path: "/refresh") else {
            isAuthenticated = false
            isLoading = false
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["refresh_token": refreshToken])
        await performSpotifyTokenRequest(request)
    }

    private func performSpotifyTokenRequest(_ request: URLRequest) async {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                isAuthenticated = false
                isLoading = false
                return
            }
            if let tokenResponse = try? JSONDecoder().decode(AccessTokenResponse.self, from: data) {
                accessToken = tokenResponse.accessToken
                tokenType = tokenResponse.tokenType
                keychain.set(tokenResponse.accessToken, forKey: "spotifyAccessToken")
                keychain.set(tokenResponse.tokenType, forKey: "spotifyTokenType")
                if let newRefreshToken = tokenResponse.refreshToken {
                    keychain.set(newRefreshToken, forKey: "spotifyRefreshToken")
                }
                isAuthenticated = true
            } else {
                isAuthenticated = false
            }
        } catch {
            isAuthenticated = false
        }
        isLoading = false
    }

    // MARK: - Helpers

    private func generateRandomString(length: Int) -> String {
        let byteCount = length / 2
        var bytes = [UInt8](repeating: 0, count: byteCount)
        guard SecRandomCopyBytes(kSecRandomDefault, byteCount, &bytes) == errSecSuccess else {
            return ""
        }
        return bytes.map { String(format: "%02x", $0) }.joined()
            .padding(toLength: length, withPad: "0", startingAt: 0)
    }

    private func backendURL(path: String) -> URL? {
        guard let base = Bundle.main.object(forInfoDictionaryKey: "BACKEND_API_URL") as? String,
              !base.isEmpty else { return nil }
        return URL(string: "\(base)\(path)")
    }
}
