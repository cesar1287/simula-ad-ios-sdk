//
//  MiniGameMenu.swift
//  ad-sdk-ios
//
//  Created by Cesar Rodrigues Nascimento on 22/05/26.
//

import SwiftUI
import ImageIO
import SafariServices
import StoreKit

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
    public var onImpression: ((String) -> Void)? = nil
    public var onDestinationOpen: ((String, String) -> Void)? = nil
    
    // MARK: - Internal States
    
    @EnvironmentObject private var provider: MiniGameProvider
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    @State private var games: [GameData] = []
    @State private var menuId: String? = nil
    @State private var isLoadingCatalog: Bool = false
    @State private var catalogError: Bool = false
    @State private var currentGridPageIndex = 0
    
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
        onGameClose: ((String) -> Void)? = nil,
        onImpression: ((String) -> Void)? = nil,
        onDestinationOpen: ((String, String) -> Void)? = nil
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
        self.onImpression = onImpression
        self.onDestinationOpen = onDestinationOpen
    }
    
    // MARK: - Body Layout
    
    public var body: some View {
        GeometryReader { outerGeometry in
            ZStack {
                if isOpen {
                    // Background overlay scrim
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            isOpen = false
                        }
                        .transition(AnyTransition.opacity)
                    
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
                                catalogContentView(viewport: outerGeometry)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .frame(width: sizeClass == .regular ? outerGeometry.size.width * 0.90 : nil)
                    .frame(height: sizeClass == .regular ? outerGeometry.size.height * 0.95 : 640)
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
                    .transition(AnyTransition.asymmetric(
                        insertion: AnyTransition.move(edge: .bottom).combined(with: AnyTransition.opacity),
                        removal: AnyTransition.move(edge: .bottom).combined(with: AnyTransition.opacity)
                    ))
                    .onAppear {
                        loadMinigamesCatalog()
                    }
                }
            }
            .frame(width: outerGeometry.size.width, height: outerGeometry.size.height)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isOpen)
        }
        // MARK: - Game View Overlay Sheet
        .fullScreenCover(isPresented: Binding(
            get: { isGameActive && activeGameUrl != nil },
            set: { newValue in
                isGameActive = newValue
                if !newValue {
                    activeGameUrl = nil
                }
            }
        )) {
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
        .fullScreenCover(isPresented: Binding(
            get: { isAdActive && activeAdUrl != nil },
            set: { newValue in
                isAdActive = newValue
                if !newValue {
                    activeAdUrl = nil
                }
            }
        )) {
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
            ZStack(alignment: .trailing) {
                // Joystick badge overlap (drawn behind)
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color.pink, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: 24)
                .zIndex(0) // Explicitly set behind
                
                // Character Avatar (drawn in front)
                AsyncImage(url: URL(string: charImage)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        // Initials Fallback matching Javascript getInitials
                        ZStack {
                            Color(hex: theme.backgroundColor ?? "#0b0b0f")
                            Text(getInitials(name: charName))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(width: 48, height: 48)
                .background(Color(hex: theme.backgroundColor ?? "#0b0b0f")) // Solid opaque background
                .clipShape(RoundedRectangle(cornerRadius: 16)) // Ensure opaque clipping
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1.5)
                )
                .shadow(radius: 6)
                .zIndex(1) // Explicitly set in front
            }
            .padding(.trailing, 24) // offset adjustment so the text is not overlapped
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Play a Game with")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text(charName)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
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
    
    private var gridGames: [GameData] {
        Array(games.prefix(maxGamesToShow))
    }
    
    private var chunkedGridGames: [[GameData]] {
        gridGames.chunked(into: 4)
    }
    
    private var tabletChunkedGridGames: [[GameData]] {
        gridGames.chunked(into: 2)
    }
    
    private func catalogContentView(viewport: GeometryProxy) -> some View {
        Group {
            if sizeClass == .regular {
                // Horizontal paginated grid-carousel layout on regular horizontal classes (e.g. iPad, landscape orientation)
                // Shows exactly 2 visible cards and 2 peeking cards on the sides, with smooth dragging/snapping
                let ipadDialogWidth = viewport.size.width * 0.90
                let ipadCardWidth = (ipadDialogWidth - 128) / 2
                let ipadCardHeight = min(viewport.size.height * 0.73, ipadCardWidth * 1.95)
                
                VStack(spacing: 12) {
                    TabletPagingCarousel(
                        items: gridGames,
                        theme: theme,
                        cardHeight: ipadCardHeight,
                        selectMinigame: { game in selectMinigame(game) },
                        currentIndex: $currentGridPageIndex
                    )
                    .frame(height: ipadCardHeight + 20)
                    
                    // Small premium blue page indicator indicating how many pages are left
                    if tabletChunkedGridGames.count > 1 {
                        HStack(spacing: 8) {
                            ForEach(0..<tabletChunkedGridGames.count, id: \.self) { index in
                                let isSelected = index == getOriginalPageIndex(for: currentGridPageIndex, count: tabletChunkedGridGames.count)
                                Capsule()
                                    .fill(isSelected ? Color(hex: theme.accentColor ?? "#007aff") : Color.white.opacity(0.15))
                                    .frame(width: isSelected ? 18 : 6, height: 6)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentGridPageIndex)
                            }
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 8)
                    }
                }
            } else {
                // Snapping Paging Carousel on compact width layout (e.g. iPhone)
                PagingCarousel(items: gridGames, currentIndex: $currentGridPageIndex) { game, cardWidth in
                    GameCardBig(game: game, theme: theme, width: cardWidth, height: cardWidth * 1.75, nameFontSize: 16) {
                        selectMinigame(game)
                    }
                }
                .frame(height: 440)
            }
        }
    }
    
    // MARK: - Logic Orchestration
    
    private func getOriginalPageIndex(for virtualIndex: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let remainder = virtualIndex % count
        return remainder >= 0 ? remainder : remainder + count
    }
    
    private func getInitials(name: String) -> String {
        let parts = name.components(separatedBy: " ")
        let initials = parts.compactMap { $0.first }
        return String(initials.prefix(2)).uppercased()
    }
    @MainActor
    private func loadMinigamesCatalog() {
        guard !isLoadingCatalog else { return }
        
        isLoadingCatalog = true
        catalogError = false
        currentGridPageIndex = 0
        
        Task {
            do {
                let catalog = try await APIClient.shared.fetchCatalog(devMode: provider.devMode)
                self.games = catalog.games
                self.menuId = catalog.menuId
                isLoadingCatalog = false
                onImpression?(catalog.menuId)
            } catch {
                catalogError = true
                isLoadingCatalog = false
            }
        }
    }
    @MainActor
    private func selectMinigame(_ game: GameData) {
        // Intercept destination mappings (from JSON or hardcoded testing keys)
        let isAppStoreDest = game.destinationType == "app" || game.id == "boop_the_snoot"
        let isWebViewDest = game.destinationType == "web" || game.destinationType == "url" || game.id == "blackjack"
        
        if isAppStoreDest || isWebViewDest {
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
            
            let targetValue = game.destinationTarget ?? (isAppStoreDest ? "431174690" : "https://apple.com")
            let destType = isAppStoreDest ? "app" : "web"
            
            onDestinationOpen?(destType, targetValue)
            
            if let rootVC = AdDestinationPresenter.shared.getRootViewController() {
                if isAppStoreDest {
                    AdDestinationPresenter.shared.presentAppStore(appId: targetValue, from: rootVC) {
                        // Dismiss returns to game menu
                    }
                } else if let url = URL(string: targetValue) {
                    AdDestinationPresenter.shared.presentWebView(url: url, from: rootVC) {
                        // Dismiss returns to game menu
                    }
                }
            }
            return
        }

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
                var size = CGSize(width: 375, height: 812)
                if let windowScene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first(where: { $0.activationState == .foregroundActive }) {
                    size = windowScene.screen.bounds.size
                } else if let windowScene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first {
                    size = windowScene.screen.bounds.size
                }
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
    
    @MainActor
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
    @MainActor
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

struct GameCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct GameCardBig: View {
    let game: GameData
    let theme: MiniGameTheme
    let width: CGFloat?
    let height: CGFloat?
    let nameFontSize: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                // Background Cover Image spanning the entire card
                GIFImage(urlString: game.gifCover ?? game.iconUrl, fallbackText: game.iconFallback ?? "🎮", width: width)
                    .modifier(CardFrameModifier(width: width, height: height))
                    .clipped()
                
                // Bottom-aligned LinearGradient scrim for readability
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.3),
                        Color.black.opacity(0.85)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Game Name Overlay at bottom-left
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.name)
                        .font(.system(size: nameFontSize, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .modifier(CardFrameModifier(width: width, height: height))
            .background(Color.white.opacity(0.02))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(GameCardButtonStyle())
    }
}

struct CardFrameModifier: ViewModifier {
    let width: CGFloat?
    let height: CGFloat?
    
    func body(content: Content) -> some View {
        if let w = width, let h = height {
            content
                .frame(width: w, height: h)
        } else {
            content
                .frame(maxWidth: .infinity)
                .aspectRatio(240/420, contentMode: .fit)
        }
    }
}

// MARK: - Reusable Snapping Paging Carousel Component

struct PagingCarousel<Content: View, T: Identifiable>: View {
    let items: [T]
    let spacing: CGFloat
    let peekWidth: CGFloat
    let content: (T, CGFloat) -> Content
    
    @Binding var currentIndex: Int
    @State private var dragOffset: CGFloat = 0
    
    init(
        items: [T],
        spacing: CGFloat = 16,
        peekWidth: CGFloat = 24,
        currentIndex: Binding<Int>,
        @ViewBuilder content: @escaping (T, CGFloat) -> Content
    ) {
        self.items = items
        self.spacing = spacing
        self.peekWidth = peekWidth
        self._currentIndex = currentIndex
        self.content = content
    }
    
    private func getOriginalIndex(for virtualIndex: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let remainder = virtualIndex % count
        return remainder >= 0 ? remainder : remainder + count
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            // Card width is container width minus peeking on both sides and spacing
            let cardWidth = max(50, width - (peekWidth * 2) - (spacing * 2))
            let totalWidth = cardWidth + spacing
            
            if items.count > 0 {
                let visualCenter = currentIndex
                
                ZStack {
                    // Render sliding window of 5 cards dynamically centered around the current index
                    ForEach((visualCenter - 2)...(visualCenter + 2), id: \.self) { virtualIndex in
                        let originalIndex = getOriginalIndex(for: virtualIndex, count: items.count)
                        let item = items[originalIndex]
                        
                        // Real-time positional offsets
                        let xOffset = CGFloat(virtualIndex - currentIndex) * totalWidth + dragOffset
                        
                        // Smooth scale & opacity interpolation based on exact real-time distance
                        let distance = xOffset / totalWidth
                        let absDistance = min(1.0, abs(distance))
                        let scale = 1.0 - (absDistance * 0.07)
                        let opacity = 1.0 - (absDistance * 0.40)
                        
                        content(item, cardWidth)
                            .frame(width: cardWidth)
                            .scaleEffect(scale)
                            .opacity(opacity)
                            .offset(x: xOffset)
                            .zIndex(2.0 - absDistance)
                    }
                }
                .frame(width: width, height: geometry.size.height, alignment: .center)
                .contentShape(Rectangle()) // Make the empty space interactive
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 30
                            let predictedDrag = value.predictedEndTranslation.width
                            let dragTranslation = value.translation.width
                            
                            // Determine navigation delta using projected swipe (velocity + translation)
                            var delta = Int(round(-predictedDrag / totalWidth))
                            
                            if delta == 0 {
                                if dragTranslation < -threshold || predictedDrag < -threshold {
                                    delta = 1
                                } else if dragTranslation > threshold || predictedDrag > threshold {
                                    delta = -1
                                }
                            }
                            
                            // Clamp to max 3 items to preserve context and avoid excessive skipping
                            delta = max(-3, min(3, delta))
                            
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.85)) {
                                currentIndex += delta
                                dragOffset = 0
                            }
                        }
                )
            } else {
                Color.clear
            }
        }
    }
}

struct TabletPagingCarousel: View {
    let items: [GameData]
    let theme: MiniGameTheme
    let cardHeight: CGFloat
    let selectMinigame: (GameData) -> Void
    
    @Binding var currentIndex: Int
    @State private var dragOffset: CGFloat = 0
    
    private let spacing: CGFloat = 16
    private let peekWidth: CGFloat = 40
    
    private var paddedItems: [GameData] {
        if items.isEmpty { return [] }
        if items.count % 2 == 0 {
            return items
        } else {
            return items + [items[0]]
        }
    }
    
    private func getOriginalPageIndex(for virtualIndex: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let remainder = virtualIndex % count
        return remainder >= 0 ? remainder : remainder + count
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            // Calculate cardWidth based on two visible cards, spacing, and peeking
            let cardWidth = max(50, (width - (peekWidth * 2) - (spacing * 3)) / 2)
            let totalPageWidth = (cardWidth * 2) + (spacing * 2) // Shift distance from page P to P+1
            
            let totalPages = paddedItems.count / 2
            
            if !paddedItems.isEmpty {
                let visualCenter = currentIndex
                
                ZStack {
                    ForEach((visualCenter - 2)...(visualCenter + 2), id: \.self) { virtualPageIndex in
                        let realPageIndex = getOriginalPageIndex(for: virtualPageIndex, count: totalPages)
                        let xOffset = CGFloat(virtualPageIndex - currentIndex) * totalPageWidth + dragOffset
                        
                        let distance = xOffset / totalPageWidth
                        let absDistance = min(1.0, abs(distance))
                        let scale = 1.0 - (absDistance * 0.05)
                        let opacity = 1.0 - (absDistance * 0.40)
                        
                        HStack(spacing: spacing) {
                            // Left Card
                            if realPageIndex * 2 < paddedItems.count {
                                let game = paddedItems[realPageIndex * 2]
                                GameCardBig(game: game, theme: theme, width: cardWidth, height: cardHeight, nameFontSize: 14) {
                                    selectMinigame(game)
                                }
                            }
                            
                            // Right Card
                            if realPageIndex * 2 + 1 < paddedItems.count {
                                let game = paddedItems[realPageIndex * 2 + 1]
                                GameCardBig(game: game, theme: theme, width: cardWidth, height: cardHeight, nameFontSize: 14) {
                                    selectMinigame(game)
                                }
                            }
                        }
                        .frame(width: (cardWidth * 2) + spacing)
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .offset(x: xOffset)
                    }
                }
                .frame(width: width, height: geometry.size.height, alignment: .center)
                .contentShape(Rectangle()) // Make the empty space interactive
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 30
                            let predictedDrag = value.predictedEndTranslation.width
                            let dragTranslation = value.translation.width
                            
                            // Determine navigation delta using projected swipe (velocity + translation)
                            var delta = Int(round(-predictedDrag / totalPageWidth))
                            
                            if delta == 0 {
                                if dragTranslation < -threshold || predictedDrag < -threshold {
                                    delta = 1
                                } else if dragTranslation > threshold || predictedDrag > threshold {
                                    delta = -1
                                }
                            }
                            
                            // Clamp to max 1 page transitions to preserve smooth progression
                            delta = max(-1, min(1, delta))
                            
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.85)) {
                                currentIndex += delta
                                dragOffset = 0
                            }
                        }
                )
            } else {
                Color.clear
            }
        }
    }
}

struct SwiftUIAnimatedImageView: UIViewRepresentable {
    let uiImage: UIImage
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.image = uiImage
    }
}

// MARK: - Native High-Performance GIF Rendering View

struct GIFImage: View {
    let urlString: String
    let fallbackText: String
    let width: CGFloat?
    
    @State private var gifImage: UIImage? = nil
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if let image = gifImage {
                SwiftUIAnimatedImageView(uiImage: image)
                    .transition(AnyTransition.opacity.combined(with: AnyTransition.scale(scale: 0.98)))
            } else if isLoading {
                ZStack {
                    Color.white.opacity(0.04)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.3)))
                }
            } else {
                ZStack {
                    Color.white.opacity(0.04)
                    VStack(spacing: 8) {
                        Text(fallbackText)
                            .font(.system(size: (width ?? 138) * 0.25))
                    }
                }
            }
        }
        .onAppear {
            loadImage()
        }
        .onValueChange(of: urlString) {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        isLoading = true
        gifImage = nil
        
        Task {
            do {
                let image = try await Task.detached(priority: .userInitiated) { () -> UIImage? in
                    let (data, _) = try await URLSession.shared.data(from: url)
                    return UIImage.animatedImage(withGIFData: data)
                }.value
                
                withAnimation(.easeOut(duration: 0.25)) {
                    self.gifImage = image
                    self.isLoading = false
                }
            } catch {
                withAnimation(.easeOut(duration: 0.25)) {
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - CoreGraphics/ImageIO UIImage GIF parsing extension

extension UIImage {
    static func animatedImage(withGIFData data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let count = CGImageSourceGetCount(source)
        
        if count <= 1 {
            return UIImage(data: data)
        }
        
        var images = [UIImage]()
        var duration = 0.0
        
        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: cgImage))
                let delaySeconds = delayForImageAtIndex(i, source: source)
                duration += delaySeconds
            }
        }
        
        return UIImage.animatedImage(with: images, duration: duration)
    }
    
    private static func delayForImageAtIndex(_ index: Int, source: CGImageSource) -> Double {
        var delay = 0.1
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        
        if let cfProperties = cfProperties as? [String: Any],
           let gifProperties = cfProperties[kCGImagePropertyGIFDictionary as String] as? [String: Any] {
            
            if let delayTime = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double {
                delay = delayTime
            } else if let delayTime = gifProperties[kCGImagePropertyGIFDelayTime as String] as? Double {
                delay = delayTime
            }
        }
        
        if delay < 0.02 {
            delay = 0.1
        }
        
        return delay
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

@MainActor
public class AdDestinationPresenter: NSObject, SKStoreProductViewControllerDelegate, SFSafariViewControllerDelegate {
    public static let shared = AdDestinationPresenter()
    
    private var onDismissCallback: (() -> Void)?
    
    public func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) ??
            UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        
        var topVC = rootVC
        while let presentedVC = topVC.presentedViewController {
            topVC = presentedVC
        }
        return topVC
    }
    
    public func presentAppStore(appId: String, from viewController: UIViewController, onDismiss: @escaping () -> Void) {
        self.onDismissCallback = onDismiss
        
        let storeViewController = SKStoreProductViewController()
        storeViewController.delegate = self
        
        // Present immediately so the user sees the native App Store sheet instantly
        viewController.present(storeViewController, animated: true) {
            let parameters = [SKStoreProductParameterITunesItemIdentifier: appId]
            storeViewController.loadProduct(withParameters: parameters) { (success, error) in
                if !success {
                    print("[Simula SDK] Failed to load App Store product details: \(error?.localizedDescription ?? "unknown error"). User can still dismiss manually via Close button.")
                }
            }
        }
    }
    
    public func presentWebView(url: URL, from viewController: UIViewController, onDismiss: @escaping () -> Void) {
        self.onDismissCallback = onDismiss
        
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.delegate = self
        
        viewController.present(safariViewController, animated: true, completion: nil)
    }
    
    // MARK: - SKStoreProductViewControllerDelegate
    public func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true) { [weak self] in
            self?.onDismissCallback?()
            self?.onDismissCallback = nil
        }
    }
    
    // MARK: - SFSafariViewControllerDelegate
    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        onDismissCallback?()
        onDismissCallback = nil
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

extension View {
    @ViewBuilder
    func onValueChange<T: Equatable>(of value: T, perform action: @escaping () -> Void) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: value) { oldValue, newValue in
                action()
            }
        } else {
            self.onChange(of: value) { newValue in
                action()
            }
        }
    }
}
