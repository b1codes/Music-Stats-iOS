//
//  AuthManager.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 8/1/25.
//

import Foundation
import KeychainSwift

@MainActor
class AuthManager: ObservableObject {

    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = true
    @Published var authState: String?

    var accessToken: String?
    var tokenType: String?

    private var keychain = KeychainSwift()

    init() {
        if keychain.get("refreshToken") != nil {
            Task { await refreshToken() }
        } else {
            isLoading = false
        }
    }

    func getAuthorizationURL() -> String {
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
        let scope = "user-read-private user-read-email user-top-read"
        let responseType = "code"

        components.queryItems = [
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "response_type", value: responseType),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "client_id", value: spotifyClientID)
        ]
        return components.string ?? ""
    }

    private func generateRandomString(length: Int) -> String {
        let byteCount = length / 2
        var bytes = [UInt8](repeating: 0, count: byteCount)
        let result = SecRandomCopyBytes(kSecRandomDefault, byteCount, &bytes)
        guard result == errSecSuccess else {
            return ""
        }
        let hexString = bytes.map { String(format: "%02x", $0) }.joined()
        return hexString.padding(toLength: length, withPad: "0", startingAt: 0)
    }

    func logIn(with code: String) {
        isLoading = true
        Task { await exchangeCodeForTokens(code: code) }
    }

    func logout() {
        accessToken = nil
        tokenType = nil
        keychain.clear()
        isAuthenticated = false
    }

    func refreshToken() async {
        guard let refreshToken = keychain.get("refreshToken") else {
            isAuthenticated = false
            isLoading = false
            return
        }

        let urlRequest = createTokenURLRequest()
        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken)
        ]
        var request = urlRequest
        request.httpBody = bodyComponents.query?.data(using: .utf8)
        await performTokenRequest(request)
    }

    private func createTokenURLRequest() -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "accounts.spotify.com"
        components.path = "/api/token"

        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = "POST"

        let spotifyClientID = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_API_CLIENT_ID") as? String
        let spotifyClientSecret = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_API_CLIENT_SECRET") as? String
        let combo = "\(spotifyClientID ?? ""):\(spotifyClientSecret ?? "")"
        let comboEncoded = combo.data(using: .utf8)?.base64EncodedString()

        urlRequest.allHTTPHeaderFields = [
            "Authorization": "Basic \(comboEncoded!)",
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        return urlRequest
    }

    private func performTokenRequest(_ request: URLRequest) async {
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
                if let newRefreshToken = tokenResponse.refreshToken {
                    keychain.set(newRefreshToken, forKey: "refreshToken")
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

    private func exchangeCodeForTokens(code: String) async {
        let urlRequest = createTokenURLRequest()

        let redirectURIHost = Bundle.main.object(forInfoDictionaryKey: "REDIRECT_URI_HOST") as? String
        let redirectURIScheme = Bundle.main.object(forInfoDictionaryKey: "REDIRECT_URI_SCHEME") as? String
        let redirectURI = "\(redirectURIScheme ?? "")://\(redirectURIHost ?? "")"

        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: redirectURI)
        ]
        var request = urlRequest
        request.httpBody = bodyComponents.query?.data(using: .utf8)
        await performTokenRequest(request)
    }
}
