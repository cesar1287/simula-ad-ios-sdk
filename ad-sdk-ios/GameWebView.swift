//
//  GameWebView.swift
//  ad-sdk-ios
//
//  Created by Cesar Rodrigues Nascimento on 22/05/26.
//

import SwiftUI
import WebKit

/// A SwiftUI wrapper around WKWebView that embeds the Simula Game Widget Shell.
/// Intercepts Javascript postMessage calls from the shell and processes them natively using modern Swift concurrency.
public struct GameWebView: View {
    let gameUrl: String
    let showBanner: Bool
    let serveId: String?
    let devMode: Bool
    let onAdIdReceived: (String) -> Void
    let onServeIdReceived: (String) -> Void
    
    public init(
        gameUrl: String,
        showBanner: Bool = true,
        serveId: String? = nil,
        devMode: Bool = false,
        onAdIdReceived: @escaping (String) -> Void,
        onServeIdReceived: @escaping (String) -> Void
    ) {
        self.gameUrl = gameUrl
        self.showBanner = showBanner
        self.serveId = serveId
        self.devMode = devMode
        self.onAdIdReceived = onAdIdReceived
        self.onServeIdReceived = onServeIdReceived
    }
    
    public var body: some View {
        GameWebViewRepresentable(
            gameUrl: gameUrl,
            showBanner: showBanner,
            serveId: serveId,
            devMode: devMode,
            onAdIdReceived: onAdIdReceived,
            onServeIdReceived: onServeIdReceived
        )
        .background(Color.clear)
    }
}

// MARK: - UIViewRepresentable

struct GameWebViewRepresentable: UIViewRepresentable {
    let gameUrl: String
    let showBanner: Bool
    let serveId: String?
    let devMode: Bool
    let onAdIdReceived: (String) -> Void
    let onServeIdReceived: (String) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Inject JS listener to forward WidgetShell's postMessages to iOS native bridge
        let userContentController = WKUserContentController()
        let script = """
        window.addEventListener('message', function(event) {
            if (event.data && event.data.source === 'simula-widget-shell') {
                window.webkit.messageHandlers.simula.postMessage(JSON.stringify(event.data));
            }
        });
        """
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        userContentController.addUserScript(userScript)
        userContentController.add(context.coordinator, name: "simula")
        configuration.userContentController = userContentController
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.navigationDelegate = context.coordinator
        
        // Build the Widget Shell URL
        var components = URLComponents(string: "https://simula-api-701226639755.us-central1.run.app/widget/shell")
        let domain = MiniGameProvider.shared.appDomain
        let queryItems = [
            URLQueryItem(name: "variant", value: "game"),
            URLQueryItem(name: "domain", value: domain),
            URLQueryItem(name: "game_url", value: gameUrl),
            URLQueryItem(name: "show_banner", value: String(showBanner)),
            URLQueryItem(name: "dev", value: String(devMode)),
            URLQueryItem(name: "parent_origin", value: "simula://")
        ]
        components?.queryItems = queryItems
        
        if let url = components?.url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No-op for runtime static loads
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator & Script Bridge
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let parent: GameWebViewRepresentable
        
        init(_ parent: GameWebViewRepresentable) {
            self.parent = parent
        }
        
        // Capture postMessages from WKWebView
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "simula",
                  let bodyString = message.body as? String,
                  let data = bodyString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return
            }
            
            if parent.devMode {
                print("[Simula Web Bridge] Received event: \(json)")
            }
            
            // Expected shape: { source: "simula-widget-shell", type: "adServe", data: { divId: "..." } }
            guard let type = json["type"] as? String else { return }
            
            switch type {
            case "adServe":
                if let innerData = json["data"] as? [String: Any],
                   let divId = innerData["divId"] as? String {
                    handleAdServe(divId: divId)
                }
            default:
                break
            }
        }
        
        private func handleAdServe(divId: String) {
            // Medrec reports are handled directly by the parent during close-flows to prevent double counting
            if divId.contains("medrec") { return }
            
            guard let serveId = parent.serveId,
                  let sessionId = MiniGameProvider.shared.sessionId else { return }
            
            let format = divIdToRenderedFormat(divId)
            
            Task {
                await APIClient.shared.reportAdInterstitial(
                    serveId: serveId,
                    sessionId: sessionId,
                    adSource: "aditude",
                    renderedFormat: format,
                    devMode: parent.devMode
                )
            }
        }
        
        private func divIdToRenderedFormat(_ divId: String) -> String {
            if divId.contains("banner") { return "banner" }
            if divId.contains("rail") { return "right_rail" }
            if divId.contains("rewardedmedrec") { return "medrec_rewarded" }
            if divId.contains("medrec") { return "medrec" }
            return divId
        }
    }
}
