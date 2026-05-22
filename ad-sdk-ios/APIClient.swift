//
//  APIClient.swift
//  ad-sdk-ios
//
//  Created by Cesar Rodrigues Nascimento on 22/05/26.
//

import Foundation

/// A high-performance, non-blocking API client for communication with Simula Ad services.
/// All calls run asynchronously using modern Swift Concurrency (async/await).
public final class APIClient {
    public static let shared = APIClient()
    
    private let baseURL = "https://simula-api-701226639755.us-central1.run.app"
    private let urlSession: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.ephemeral
        // Set standard performance timeouts for Ad serving
        configuration.timeoutIntervalForRequest = 8.0
        configuration.timeoutIntervalForResource = 12.0
        self.urlSession = URLSession(configuration: configuration)
    }
    
    /// Internal logger that prints only when devMode is active
    private func log(_ message: String, devMode: Bool) {
        if devMode {
            print("[Simula SDK] \(message)")
        }
    }
    
    /// Creates a server session.
    public func createSession(apiKey: String, devMode: Bool, primaryUserID: String?) async throws -> String? {
        var urlComponents = URLComponents(string: "\(baseURL)/session/create")
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "devMode", value: String(devMode))
        ]
        if let ppid = primaryUserID, !ppid.isEmpty {
            queryItems.append(URLQueryItem(name: "ppid", value: ppid))
        }
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("1", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        log("Creating session: \(url.absoluteString)", devMode: devMode)
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            return nil
        }
        
        if httpResponse.statusCode == 401 {
            throw NSError(domain: "SimulaSDK", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid API key (please check dashboard or contact Simula team for a valid API key)"])
        }
        
        guard httpResponse.statusCode == 200 else {
            log("Session creation failed with status code \(httpResponse.statusCode)", devMode: devMode)
            return nil
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let sessionId = json["sessionId"] as? String {
            return sessionId
        }
        
        return nil
    }
    
    /// Patches PPID to update the session.
    public func updateSessionPpid(sessionId: String, ppid: String, devMode: Bool) async {
        guard let url = URL(string: "\(baseURL)/session/\(sessionId)/ppid/\(ppid)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("1", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        log("Updating session PPID: \(url.absoluteString)", devMode: devMode)
        
        do {
            let (_, response) = try await urlSession.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                log("PPID update returned status: \(httpResponse.statusCode)", devMode: devMode)
            }
        } catch {
            log("Failed to update PPID: \(error.localizedDescription)", devMode: devMode)
        }
    }
    
    /// Fetches the catalog of available minigames.
    public func fetchCatalog(devMode: Bool) async throws -> (menuId: String, games: [GameData]) {
        guard let url = URL(string: "\(baseURL)/minigames/catalogv2") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("1", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        log("Fetching catalog from: \(url.absoluteString)", devMode: devMode)
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let payload = try JSONDecoder().decode(CatalogResponsePayload.self, from: data)
        let menuId = payload.menuId ?? ""
        
        // Handle different structural types returned by backend
        let gamesList = payload.catalog ?? payload.data ?? []
        return (menuId, gamesList)
    }
    
    /// Initialises a game state to retrieve target game urls and ad/serve context IDs.
    func initMinigame(request: InitMinigameRequestPayload, devMode: Bool) async throws -> MinigameResponsePayload {
        guard let url = URL(string: "\(baseURL)/minigames/init") else {
            throw URLError(.badURL)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("1", forHTTPHeaderField: "ngrok-skip-browser-warning")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        log("Initializing minigame \(request.gameType)", devMode: devMode)
        
        let (data, response) = try await urlSession.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(MinigameResponsePayload.self, from: data)
    }
    
    /// Obtains standard fallback interstitial ad url.
    public func fetchAdForMinigame(adId: String, sessionId: String, devMode: Bool) async -> String? {
        guard let encodedSessionId = sessionId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/minigames/fallback_ad/\(adId)?session_id=\(encodedSessionId)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        log("Fetching fallback ad for \(adId)", devMode: devMode)
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }
            
            if let payload = try? JSONDecoder().decode(MinigameResponsePayload.self, from: data) {
                return payload.adResponse.iframeUrl
            }
        } catch {
            log("Error fetching fallback ad: \(error.localizedDescription)", devMode: devMode)
        }
        
        return nil
    }
    
    /// Reports ad interaction and view stats to the SSP.
    /// Runs as a fire-and-forget background task using URLSessionConfiguration.background if necessary,
    /// but here standard task execution guarantees background delivery.
    public func reportAdInterstitial(serveId: String, sessionId: String, adSource: String, renderedFormat: String?, devMode: Bool) async {
        guard let encodedServeId = serveId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/minigames/play/\(encodedServeId)/ad-interstitial") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("1", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let payload = AdInterstitialReportPayload(
            sessionId: sessionId,
            adSource: adSource,
            renderedFormat: renderedFormat
        )
        
        request.httpBody = try? JSONEncoder().encode(payload)
        
        log("Reporting ad interstitial serveId:\(serveId), source:\(adSource), format:\(renderedFormat ?? "none")", devMode: devMode)
        
        do {
            let (_, response) = try await urlSession.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                log("Report ad interstitial returned code: \(httpResponse.statusCode)", devMode: devMode)
            }
        } catch {
            log("Failed to report ad interstitial: \(error.localizedDescription)", devMode: devMode)
        }
    }
    
    /// Fetches Aditude configuration for a specific host app identifier/domain.
    public func fetchAditudeConfig(domain: String, devMode: Bool) async -> AditudeConfig? {
        guard let encodedDomain = domain.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/aditude/config?domain=\(encodedDomain)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("1", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        log("Fetching Aditude config for domain \(domain)", devMode: devMode)
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }
            
            return try JSONDecoder().decode(AditudeConfig.self, from: data)
        } catch {
            log("Failed to fetch Aditude Config: \(error.localizedDescription)", devMode: devMode)
            return nil
        }
    }
    
    /// Fires best-effort game click tracking.
    public func trackMenuGameClick(menuId: String, gameName: String, apiKey: String, devMode: Bool) async {
        guard let url = URL(string: "\(baseURL)/minigames/menu/track/click") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("1", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let body: [String: String] = [
            "menu_id": menuId,
            "game_name": gameName
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        log("Tracking game click: \(gameName)", devMode: devMode)
        
        do {
            let (_, _) = try await urlSession.data(for: request)
        } catch {
            log("Failed to track game click: \(error.localizedDescription)", devMode: devMode)
        }
    }
}
