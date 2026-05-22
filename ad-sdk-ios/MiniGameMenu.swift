//
//  MiniGameMenu.swift
//  ad-sdk-ios
//
//  Created by Cesar Rodrigues Nascimento on 22/05/26.
//

import SwiftUI

/// The master SwiftUI View for displaying the MiniGame catalog overlay.
/// Features a responsive layout that automatically adapts to trait-collections:
/// - Compact Width (e.g. iPhones in portrait): Displays a paginated carousel utilizing TabView.
/// - Regular Width (e.g. iPads or iPhones in landscape): Displays a fixed 4-column LazyVGrid layout.
/// Features a breathtaking, premium dark mode aesthetic with radial glow points.
public struct MiniGameMenu: View {
    @Binding public var isOpen: Bool
    
    // Character configuration parameters
    public let charName: String
    public let charID: String
    public let charImage: String
    public let messages: [Message]
    public let charDesc: String?
    public let convId: String?
    public let entryPoint: String?
    
    // UI Theme and presentation customization
    public var maxGamesToShow: Int = 6
    public var theme: MiniGameTheme = MiniGameTheme()
    public var delegateChar: Bool = true
    public var showBanner: Bool = true
    
    // Navigation type (kept for API matching)
    public var navigationType: String = "dot"
    
    // Publisher events callbacks
    public var onGameOpen: ((String, String) -> Void)? = nil
    public var onGameClose: ((String) -> Void)? = nil
    
    // MARK: - Internal States
    
    @EnvironmentObject private var provider: MiniGameProvider
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    @State private var games: [GameData] = []
    @State private var menuId: String? = nil
    @State private var isLoadingCatalog: Bool = false
    @State private var catalogError: Bool = false
    
    // Dynamic Game & Interstitial Ad tracking
    @State private var selectedGame: GameData? = nil
    @State private var activeGameUrl: String? = nil
    @State private var currentAdId: String? = nil
    @State private var currentServeId: String? = nil
    @State private var isGameActive: Bool = false
    
    // Fallback Ad Presentation
    @State private var activeAdUrl: String? = nil
    @State private var isAdActive: Bool = false
    @State private var isAditudeAd: Bool = false
    @State private var hasPlayedAd: Bool = false
    
    public init(
        isOpen: Binding<Bool>,
        charName: String,
        charID: String,
        charImage: String,
        messages: [Message] = [],
        charDesc: String? = nil,
        convId: String? = nil,
        entryPoint: String? = nil,
        maxGamesToShow: Int = 6,
        theme: MiniGameTheme = MiniGameTheme(),
        delegateChar: Bool = true,
        showBanner: Bool = true,
        navigationType: String = "dot",
        onGameOpen: ((String, String) -> Void)? = nil,
        onGameClose: ((String) -> Void)? = nil
    ) {
        self._isOpen = isOpen
        self.charName = charName
        self.charID = charID
        self.charImage = charImage
        self.messages = messages
        self.charDesc = charDesc
        self.convId = convId
        self.entryPoint = entryPoint
        self.maxGamesToShow = maxGamesToShow
        self.theme = theme
        self.delegateChar = delegateChar
        self.showBanner = showBanner
        self.navigationType = navigationType
        self.onGameOpen = onGameOpen
        self.onGameClose = onGameClose
    }
    
    // MARK: - Body Layout
    
    public var body: some View {
        ZStack {
            if isOpen {
                // Background overlay scrim
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isOpen = false
                    }
                    .transition(.opacity)
                
                // Visual Shell Container
                VStack(spacing: 0) {
                    // Header Bar with initials and character name
                    menuHeaderView
                    
                    // Body Game catalog area
                    Group {
                        if isLoadingCatalog {
                            loadingView
                        } else if catalogError {
                            errorView
                        } else {
                            catalogContentView
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .frame(maxWidth: sizeClass == .regular ? 640 : .infinity)
                .frame(height: sizeClass == .regular ? 540 : 640)
                .background(
                    ZStack {
                        // Core solid background matching the original dark theme
                        Color(hex: theme.backgroundColor ?? "#0b0b0f")
                        
                        // Captivating glowing radial gradients for maximum aesthetic appeal
                        RadialGradient(
                            colors: [Color.blue.opacity(0.12), Color.clear],
                            center: .topLeading,
                            startRadius: 5,
                            endRadius: 360
                        )
                        RadialGradient(
                            colors: [Color.purple.opacity(0.08), Color.clear],
                            center: .topTrailing,
                            startRadius: 5,
                            endRadius: 320
                        )
                        RadialGradient(
                            colors: [Color.cyan.opacity(0.09), Color.clear],
                            center: .bottom,
                            startRadius: 10,
                            endRadius: 400
                        )
                    }
                )
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 30, x: 0, y: 15)
                .padding(.horizontal, sizeClass == .regular ? 0 : 16)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
                .onAppear {
                    loadMinigamesCatalog()
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isOpen)
        // MARK: - Game View Overlay Sheet
        .fullScreenCover(isPresented: $isGameActive) {
            if let gameUrl = activeGameUrl {
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    GameWebView(
                        gameUrl: gameUrl,
                        showBanner: showBanner,
                        serveId: currentServeId,
                        devMode: provider.devMode,
                        onAdIdReceived: { adId in
                            self.currentAdId = adId
                        },
                        onServeIdReceived: { serveId in
                            self.currentServeId = serveId
                        }
                    )
                    
                    // Absolute Close button overlay
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                closeActiveGameFlow()
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.3), radius: 4)
                            }
                            .padding(.trailing, 20)
                            .padding(.top, 20)
                        }
                        Spacer()
                    }
                }
            }
        }
        // MARK: - Fallback Ad Overlay Sheet
        .fullScreenCover(isPresented: $isAdActive) {
            if let adUrl = activeAdUrl {
                AdWebView(
                    adUrl: adUrl,
                    isAditude: isAditudeAd,
                    serveId: currentServeId,
                    devMode: provider.devMode,
                    onClose: {
                        isAdActive = false
                        onGameClose?(selectedGame?.name ?? "")
                        selectedGame = nil
                    }
                )
            }
        }
    }
    
    // MARK: - Subviews
    
    private var menuHeaderView: some View {
        HStack(spacing: 16) {
            // Overlapping Character Image and Game Icon Spot
            ZStack(alignment: .bottomTrailing) {
                // Character Avatar
                AsyncImage(url: URL(string: charImage)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .cover)
                    default:
                        // Initials Fallback matching Javascript getInitials
                        ZStack {
                            Color.white.opacity(0.08)
                            Text(getInitials(name: charName))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(width: 64, height: 64)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1.5)
                )
                .shadow(radius: 6)
                
                // Sparkle Controller game controller overlaps
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color.pink.opacity(0.8), Color.purple.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: 6, y: 6)
            }
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Play a Game with")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(charName)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            Spacer()
            
            // Core Glassmorphic Close Menu button
            Button(action: {
                isOpen = false
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
            .padding(.top, 16)
        }
        .padding(.horizontal, 4)
    }
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.2)
            
            Text("Loading games...")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.amberHex)
            
            Text("No games are available to play right now.")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Please check back later!")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 32)
    }
    
    private var catalogContentView: some View {
        Group {
            if sizeClass == .regular {
                // Fixed 4-column Grid layout on regular horizontal classes (e.g. iPad, landscape orientation)
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                        ForEach(games.prefix(maxGamesToShow)) { game in
                            GameCard(game: game, theme: theme) {
                                selectMinigame(game)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            } else {
                // Paginated Carousel layout using TabView pageStyle on compact horizontal classes
                TabView {
                    let chunkedGames = games.prefix(maxGamesToShow).chunked(into: 3)
                    ForEach(0..<chunkedGames.count, id: \.self) { index in
                        VStack(spacing: 16) {
                            ForEach(chunkedGames[index]) { game in
                                GameCardHorizontal(game: game, theme: theme) {
                                    selectMinigame(game)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
            }
        }
    }
    
    // MARK: - Logic Orchestration
    
    private func getInitials(name: String) -> String {
        let parts = name.components(separatedBy: " ")
        let initials = parts.compactMap { $0.first }
        return String(initials.prefix(2)).uppercased()
    }
    
    private func loadMinigamesCatalog() {
        guard !isLoadingCatalog else { return }
        
        isLoadingCatalog = true
        catalogError = false
        
        Task {
            do {
                let catalog = try await APIClient.shared.fetchCatalog(devMode: provider.devMode)
                self.games = catalog.games
                self.menuId = catalog.menuId
                isLoadingCatalog = false
            } catch {
                catalogError = true
                isLoadingCatalog = false
            }
        }
    }
    
    private func selectMinigame(_ game: GameData) {
        // Track game click tracking
        if let menuId = menuId {
            Task {
                await APIClient.shared.trackMenuGameClick(
                    menuId: menuId,
                    gameName: game.name,
                    apiKey: provider.apiKey,
                    devMode: provider.devMode
                )
            }
        }
        
        selectedGame = game
        // Call UI developer callback
        onGameOpen?(game.name, game.description)
        
        // Triggers loading game url
        isLoadingCatalog = true
        
        Task {
            guard let sessionId = provider.sessionId else {
                isLoadingCatalog = false
                return
            }
            
            do {
                let size = UIScreen.main.bounds.size
                let payload = InitMinigameRequestPayload(
                    gameType: game.id,
                    sessionId: sessionId,
                    convId: convId,
                    entryPoint: entryPoint,
                    currencyMode: false,
                    w: Int(size.width),
                    h: Int(size.height),
                    charId: charID,
                    charName: charName,
                    charImage: charImage,
                    charDesc: charDesc,
                    messages: messages,
                    delegateChar: delegateChar,
                    menuId: menuId
                )
                
                let response = try await APIClient.shared.initMinigame(request: payload, devMode: provider.devMode)
                
                // Open Game WebView sheet
                self.activeGameUrl = response.adResponse.iframeUrl
                self.currentAdId = response.adResponse.adId
                self.currentServeId = response.adResponse.serveId
                
                isLoadingCatalog = false
                self.isOpen = false // Dismiss the menu, loading game is launching
                self.isGameActive = true
                self.hasPlayedAd = false
            } catch {
                isLoadingCatalog = false
                print("[Simula SDK] Failed to initialize minigame: \(error.localizedDescription)")
            }
        }
    }
    
    private func closeActiveGameFlow() {
        isGameActive = false
        
        // Trigger ad presentation if not already completed
        if !hasPlayedAd {
            hasPlayedAd = true
            
            // DevMode -> Immediately serve aditude simulation placeholder
            if provider.devMode {
                isAditudeAd = true
                activeAdUrl = "https://simula-api-701226639755.us-central1.run.app/widget/shell?variant=medrec&dev=true"
                isAdActive = true
                reportMedrecInterstitial(source: "aditude", format: "medrec")
                return
            }
            
            // Real session fallback logic
            if let adId = currentAdId, let sessionId = provider.sessionId {
                Task {
                    if let adUrl = await APIClient.shared.fetchAdForMinigame(adId: adId, sessionId: sessionId, devMode: provider.devMode) {
                        self.isAditudeAd = false
                        self.activeAdUrl = adUrl
                        self.isAdActive = true
                        self.reportMedrecInterstitial(source: "simula", format: nil)
                    } else {
                        // Fetch failed, check Aditude status
                        checkAditudeFallback()
                    }
                }
            } else {
                checkAditudeFallback()
            }
        } else {
            onGameClose?(selectedGame?.name ?? "")
            selectedGame = nil
        }
    }
    
    private func checkAditudeFallback() {
        if provider.aditudeReady, let _ = provider.aditudeConfig {
            self.isAditudeAd = true
            let domain = provider.appDomain
            self.activeAdUrl = "https://simula-api-701226639755.us-central1.run.app/widget/shell?variant=medrec&domain=\(domain)&dev=false"
            self.isAdActive = true
            reportMedrecInterstitial(source: "aditude", format: "medrec")
        } else {
            // Direct dismiss
            reportMedrecInterstitial(source: "none", format: nil)
            onGameClose?(selectedGame?.name ?? "")
            selectedGame = nil
        }
    }
    
    private func reportMedrecInterstitial(source: String, format: String?) {
        guard let serveId = currentServeId, let sessionId = provider.sessionId else { return }
        Task {
            await APIClient.shared.reportAdInterstitial(
                serveId: serveId,
                sessionId: sessionId,
                adSource: source,
                renderedFormat: format,
                devMode: provider.devMode
            )
        }
    }
}

// MARK: - Helper UI Components

struct GameCard: View {
    let game: GameData
    let theme: MiniGameTheme
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Game Cover / Icon
                AsyncImage(url: URL(string: game.gifCover ?? game.iconUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .cover)
                    default:
                        // Emoji fallback matching React design
                        ZStack {
                            Color.white.opacity(0.06)
                            Text(game.iconFallback ?? "🎮")
                                .font(.system(size: 32))
                        }
                    }
                }
                .frame(width: 80, height: 80)
                .cornerRadius(CGFloat(theme.iconCornerRadius ?? 16))
                .overlay(
                    RoundedRectangle(cornerRadius: CGFloat(theme.iconCornerRadius ?? 16))
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                
                Text(game.name)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(game.description)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 24)
            }
            .padding(12)
            .background(Color.white.opacity(isPressed ? 0.05 : 0.02))
            .cornerRadius(20)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct GameCardHorizontal: View {
    let game: GameData
    let theme: MiniGameTheme
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Game Image
                AsyncImage(url: URL(string: game.gifCover ?? game.iconUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .cover)
                    default:
                        ZStack {
                            Color.white.opacity(0.06)
                            Text(game.iconFallback ?? "🎮")
                                .font(.system(size: 26))
                        }
                    }
                }
                .frame(width: 60, height: 60)
                .cornerRadius(CGFloat(theme.iconCornerRadius ?? 14))
                .overlay(
                    RoundedRectangle(cornerRadius: CGFloat(theme.iconCornerRadius ?? 14))
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(game.description)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(14)
            .background(Color.white.opacity(isPressed ? 0.05 : 0.02))
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.04), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Extension Helpers

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    static var amberHex: Color {
        Color(red: 245/255, green: 158/255, blue: 11/255)
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
