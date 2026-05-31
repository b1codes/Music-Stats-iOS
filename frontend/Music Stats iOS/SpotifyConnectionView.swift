//
//  SpotifyConnectionView.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 8/1/25.
//

import SwiftUI
@preconcurrency import WebKit

struct SpotifyConnectionView: View {

    @EnvironmentObject var authManager: AuthManager

    @State private var showWebView = false
    @State private var authURL: String?
    @State private var code: String = ""

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Connect Spotify")
                .font(.title)
                .bold()

            Text("Connect your Spotify account to see your top songs, albums, and artists.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Button("Connect Spotify") {
                authURL = authManager.getSpotifyAuthorizationURL()
                showWebView = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .sheet(isPresented: $showWebView) {
                if let urlString = authURL, let url = URL(string: urlString) {
                    SpotifyWebView(url: url, code: $code, showWebView: $showWebView)
                        .environmentObject(authManager)
                } else {
                    ProgressView()
                }
            }
        }
        .padding()
    }
}

struct SpotifyWebView: UIViewRepresentable {

    @EnvironmentObject var authManager: AuthManager
    var url: URL
    @Binding var code: String
    @Binding var showWebView: Bool

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        context.coordinator.setupObserver(for: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.load(URLRequest(url: url))
    }

    func makeCoordinator() -> SpotifyWebViewCoordinator {
        SpotifyWebViewCoordinator(self)
    }

    class SpotifyWebViewCoordinator: NSObject, WKNavigationDelegate {
        var parent: SpotifyWebView
        private var urlObserver: NSKeyValueObservation?
        private var didFindCode = false
        private var isAwaitingFinalLoad = false

        init(_ parent: SpotifyWebView) {
            self.parent = parent
        }

        func setupObserver(for webView: WKWebView) {
            guard urlObserver == nil else { return }
            urlObserver = webView.observe(\.url, options: .new) { [weak self] webView, _ in
                guard let self, let url = webView.url, !self.didFindCode else { return }

                let scheme = Bundle.main.object(forInfoDictionaryKey: "REDIRECT_URI_SCHEME") as? String ?? ""
                let host = Bundle.main.object(forInfoDictionaryKey: "REDIRECT_URI_HOST") as? String ?? ""
                let baseURI = "\(scheme)://\(host)"

                if url.absoluteString.starts(with: baseURI),
                   self.queryParam("code", from: url.absoluteString) != nil {
                    self.didFindCode = true
                    self.isAwaitingFinalLoad = true
                }
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard isAwaitingFinalLoad else { return }
            isAwaitingFinalLoad = false

            guard let url = webView.url,
                  let code = queryParam("code", from: url.absoluteString) else { return }

            let returnedState = queryParam("state", from: url.absoluteString)
            guard returnedState == parent.authManager.authState else {
                print("Spotify OAuth state mismatch — possible CSRF attack.")
                DispatchQueue.main.async {
                    self.parent.showWebView = false
                    self.urlObserver?.invalidate()
                }
                return
            }

            DispatchQueue.main.async {
                self.parent.authManager.connectSpotify(with: code)
                self.parent.showWebView = false
                self.urlObserver?.invalidate()
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            decisionHandler(.allow)
        }

        deinit { urlObserver?.invalidate() }

        private func queryParam(_ name: String, from urlString: String) -> String? {
            URLComponents(string: urlString)?.queryItems?.first(where: { $0.name == name })?.value
        }
    }
}

#Preview {
    SpotifyConnectionView()
        .environmentObject(AuthManager())
}
