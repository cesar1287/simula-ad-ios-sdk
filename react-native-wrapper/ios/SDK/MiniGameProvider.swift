//
//  MiniGameProvider.swift
//  ad-sdk-ios
//
//  Created by Cesar Rodrigues Nascimento on 22/05/26.
//

import Foundation
import SwiftUI
import Combine

/// Thread-safe Cache Manager for storing Ad units and rendering configurations.
/// Implemented using NSRecursiveLock for high performance and strict thread-safety across background queues.
private final class MiniGameCache {
    private var adCache: [String: AdData] = [:]
    private var heightCache: [String: Double] = [:]
    private var noFillSet: Set<String> = []
    private let lock = NSRecursiveLock()
    
    private func cacheKey(slot: String, position: Int) -> String {
        return "\(slot):\(position)"
    }
    
    func getCachedAd(slot: String, position: Int) -> AdData? {
        lock.lock(); defer { lock.unlock() }
        return adCache[cacheKey(slot: slot, position: position)]
    }
    
    func cacheAd(slot: String, position: Int, ad: AdData) {
        lock.lock(); defer { lock.unlock() }
        adCache[cacheKey(slot: slot, position: position)] = ad
    }
    
    func getCachedHeight(slot: String, position: Int) -> Double? {
        lock.lock(); defer { lock.unlock() }
        return heightCache[cacheKey(slot: slot, position: position)]
    }
    
    func cacheHeight(slot: String, position: Int, height: Double) {
        lock.lock(); defer { lock.unlock() }
        heightCache[cacheKey(slot: slot, position: position)] = height
    }
    
    func hasNoFill(slot: String, position: Int) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return noFillSet.contains(cacheKey(slot: slot, position: position))
    }
    
    func markNoFill(slot: String, position: Int) {
        lock.lock(); defer { lock.unlock() }
        noFillSet.insert(cacheKey(slot: slot, position: position))
    }
}

/// The core state provider of the Simula MiniGame SDK.
/// Manages developer credentials, session lifetimes, caching mechanisms, and configuration configurations.
/// Runs UI-bound updates strictly on `@MainActor`.
@MainActor
public final class MiniGameProvider: ObservableObject {
    
    /// Global shared singleton instance for ease of use.
    public static let shared = MiniGameProvider()
    
    // MARK: - Published Properties for SwiftUI Binding
    
    @Published public private(set) var sessionId: String? = nil
    @Published public private(set) var aditudeReady: Bool = false
    @Published public private(set) var aditudeConfig: AditudeConfig? = nil
    @Published public private(set) var isInitializing: Bool = false
    @Published public private(set) var initializationError: String? = nil
    
    // MARK: - Private Core Configurations
    
    public private(set) var apiKey: String = "pub_eeee14c661ce47659a289db29364723a"
    public private(set) var devMode: Bool = false
    public private(set) var primaryUserID: String? = nil
    public private(set) var hasPrivacyConsent: Bool = true
    public private(set) var appDomain: String = "coolaigames.com"
    
    private let cache = MiniGameCache()
    private var isConfigured: Bool = false
    
    private init() {
        // Default appDomain is "coolaigames.com" for Aditude configuration compatibility
    }
    
    /// Initializes the provider with publisher credentials and configures SDK behaviors.
    /// Spawns background tasks immediately to create server sessions.
    public func configure(
        apiKey: String = "pub_eeee14c661ce47659a289db29364723a",
        primaryUserID: String? = nil,
        hasPrivacyConsent: Bool = true,
        devMode: Bool = false,
        appDomain: String? = nil
    ) {
        self.apiKey = apiKey
        self.primaryUserID = primaryUserID
        self.hasPrivacyConsent = hasPrivacyConsent
        self.devMode = devMode
        if let appDomain = appDomain {
            self.appDomain = appDomain
        }
        self.isConfigured = true
        
        // Spawn background task to boot session and load configs
        Task {
            await ensureSession()
        }
    }
    
    /// Re-evaluates primaryUserID changes and patches backend session details as needed.
    public func updatePrimaryUserID(_ newUserID: String?) {
        guard isConfigured else { return }
        
        let previousID = self.primaryUserID
        self.primaryUserID = newUserID
        
        let effectiveID = hasPrivacyConsent ? newUserID : nil
        let prevEffective = hasPrivacyConsent ? previousID : nil
        
        guard let sessionId = self.sessionId,
              let idToPatch = effectiveID,
              idToPatch != prevEffective else { return }
        
        Task {
            await APIClient.shared.updateSessionPpid(
                sessionId: sessionId,
                ppid: idToPatch,
                devMode: devMode
            )
        }
    }
    
    /// Establishes session creation and pre-fetches programmatic wrapper constraints in the background.
    private func ensureSession() async {
        guard isConfigured else { return }
        
        isInitializing = true
        initializationError = nil
        
        let effectiveUserID = hasPrivacyConsent ? primaryUserID : nil
        
        do {
            // 1. Fetch SDK Session ID from SSP
            if let fetchedSessionId = try await APIClient.shared.createSession(
                apiKey: apiKey,
                devMode: devMode,
                primaryUserID: effectiveUserID
            ) {
                self.sessionId = fetchedSessionId
                initializationError = nil
            } else {
                initializationError = "Failed to establish a valid ad session."
            }
        } catch {
            initializationError = error.localizedDescription
            print("[Simula SDK] Initialization Error: \(error.localizedDescription)")
        }
        
        // 2. Fetch Aditude wrapper configurations asynchronously (Skip in Dev Mode)
        if !devMode {
            if let config = await APIClient.shared.fetchAditudeConfig(domain: appDomain, devMode: devMode) {
                self.aditudeConfig = config
                self.aditudeReady = config.enabled
            }
        }
        
        isInitializing = false
    }
    
    // MARK: - Thread-Safe Ad Cache Facades
    
    public func getCachedAd(slot: String, position: Int) -> AdData? {
        return cache.getCachedAd(slot: slot, position: position)
    }
    
    public func cacheAd(slot: String, position: Int, ad: AdData) {
        cache.cacheAd(slot: slot, position: position, ad: ad)
    }
    
    public func getCachedHeight(slot: String, position: Int) -> Double? {
        return cache.getCachedHeight(slot: slot, position: position)
    }
    
    public func cacheHeight(slot: String, position: Int, height: Double) {
        cache.cacheHeight(slot: slot, position: position, height: height)
    }
    
    public func hasNoFill(slot: String, position: Int) -> Bool {
        return cache.hasNoFill(slot: slot, position: position)
    }
    
    public func markNoFill(slot: String, position: Int) {
        cache.markNoFill(slot: slot, position: position)
    }
}
