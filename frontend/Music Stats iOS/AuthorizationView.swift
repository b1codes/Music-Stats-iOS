//
//  AuthorizationView.swift
//  Music Stats iOS
//
//  Created by Brandon Lamer-Connolly on 11/2/23.
//

import SwiftUI
@preconcurrency import WebKit

struct WebView: UIViewRepresentable {

    @EnvironmentObject var authManager: AuthManager

    // 1
    var url: URL
    @Binding var code: String
    var state: String?
    @Binding var showWebView: Bool
    // 2
    func makeUIView(context: Context) -> WKWebView {
        let wKWebView = WKWebView()
        wKWebView.navigationDelegate = context.coordinator

        // --- ADD THIS LINE ---
        // Call the setup method immediately after creation.
        context.coordinator.setupObserver(for: wKWebView)

        return wKWebView
    }

    // 3
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }

    func getCode() -> String? {
        return self.code
    }

    func getCodeFromURL(urlString: String) -> String? {
        if let urlComponent = URLComponents(string: urlString) {
            // queryItems is an array of "key name" and "value"
            let queryItems = urlComponent.queryItems
            // to find "success" value, we need to find based on key name
            let codeValue = queryItems?.first(where: { $0.name == "code" })?.value
            // result is optional
            if codeValue == nil {
                print("Key code not found")
            } else {
                // tadaa, here is the key value
                // print("Value of code: \(codeValue!)")
            }
            return codeValue
        }
        return nil
    }

    func getStateFromURL(urlString: String) -> String? {
        if let urlComponent = URLComponents(string: urlString) {
            // queryItems is an array of "key name" and "value"
            let queryItems = urlComponent.queryItems
            // to find "success" value, we need to find based on key name
            let stateValue = queryItems?.first(where: { $0.name == "state" })?.value
            // result is optional
            if stateValue == nil {
                print("Key state not found")
            } else {
                // tadaa, here is the key value
                // print("Value of state: \(stateValue!)")
            }
            return stateValue
        }
        return nil
    }

    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(self)
    }

    class WebViewCoordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        // Properties for our logic
        private var urlObserver: NSKeyValueObservation?
        private var didFindCode = false
        private var isAwaitingFinalLoad = false // New flag to wait for the page to render

        init(_ parent: WebView) {
            self.parent = parent
        }

        // This setup method is still the most reliable place to attach the observer
        func setupObserver(for webView: WKWebView) {
            if urlObserver == nil {
                urlObserver = webView.observe(\.url, options: .new) { [weak self] webView, _ in
                    guard let self = self, let url = webView.url, !self.didFindCode else { return }

                    let redirectURIHost = Bundle.main.object(forInfoDictionaryKey: "REDIRECT_URI_HOST") as? String
                    let redirectURIScheme = Bundle.main.object(forInfoDictionaryKey: "REDIRECT_URI_SCHEME") as? String
                    let baseRedirectURI = "\(redirectURIScheme ?? "")://\(redirectURIHost ?? "")"

                    // STEP 1: Detect the redirect URL.
                    if url.absoluteString.starts(with: baseRedirectURI) {
                        // Check that the code exists in the URL.
                        if self.parent.getCodeFromURL(urlString: url.absoluteString) != nil {
                            self.didFindCode = true // Prevents this from running again.

                            // Set the flag and wait for didFinish to be called. DO NOT dismiss yet.
                            self.isAwaitingFinalLoad = true
                        }
                    }
                }
            }
        }

        // STEP 2: Wait for the page to finish loading before dismissing.
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Check if our flag was set by the observer.
            if self.isAwaitingFinalLoad {
                self.isAwaitingFinalLoad = false // Reset the flag.

                // Now that the page has rendered, we can safely parse the code and dismiss.
                guard let url = webView.url,
                      let code = self.parent.getCodeFromURL(urlString: url.absoluteString) else { return }

                let returnedState = self.parent.getStateFromURL(urlString: url.absoluteString)

                // --- STATE CHECK ---
                // Verify the state returned by Spotify matches the one we sent.
                let originalState = self.parent.authManager.authState
                guard let originalState = originalState, returnedState == originalState else {
                    print("State mismatch! Expected \(originalState ?? "nil"), but got \(returnedState ?? "nil"). Possible CSRF attack.")
                    DispatchQueue.main.async {
                        self.parent.showWebView = false
                        self.urlObserver?.invalidate()
                    }
                    return
                }

                DispatchQueue.main.async {
                    self.parent.authManager.logIn(with: code)
                    self.parent.showWebView = false
                    self.urlObserver?.invalidate()
                }
            }
        }

        // This delegate is still needed to allow navigation to proceed.
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            decisionHandler(.allow)
        }

        deinit {
            urlObserver?.invalidate()
        }
    }
}

struct AuthorizationView: View {

    @EnvironmentObject var authManager: AuthManager

    @State var showWebView: Bool = false
    @State private var authURL: String?
    @State var code: String = ""

    var body: some View {
        NavigationView {
            VStack {
                Image("AppIcon")
                    .resizable()
                    .cornerRadius(30.0)
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                Button("Authorize") {
                    // Generate fresh URL and state each time we start a new auth session
                    authURL = authManager.getAuthorizationURL()
                    showWebView = true
                }
                .padding(10)
                .sheet(isPresented: $showWebView) {
                    if let urlString = authURL, let url = URL(string: urlString) {
                        WebView(url: url, code: $code, showWebView: $showWebView)
                            .environmentObject(authManager)
                    } else {
                        ProgressView()
                    }
                }
            }
        }
    }
}

#Preview {
    AuthorizationView()
        .environmentObject(AuthManager())
}
