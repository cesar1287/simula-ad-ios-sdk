//
//  AdWebView.swift
//  ad-sdk-ios
//
//  Created by Cesar Rodrigues Nascimento on 22/05/26.
//

import SwiftUI
import WebKit

/// A premium interstitial view for displaying advertisements with a native animated circular countdown timer.
public struct AdWebView: View {
    let adUrl: String
    let isAditude: Bool
    let serveId: String?
    let devMode: Bool
    let onClose: () -> Void
    
    @State private var timeRemaining: Int = 5
    @State private var circleProgress: CGFloat = 1.0
    @State private var timerActive = true
    
    public init(
        adUrl: String,
        isAditude: Bool = false,
        serveId: String? = nil,
        devMode: Bool = false,
        onClose: @escaping () -> Void
    ) {
        self.adUrl = adUrl
        self.isAditude = isAditude
        self.serveId = serveId
        self.devMode = devMode
        self.onClose = onClose
    }
    
    public var body: some View {
        ZStack {
            // Semi-transparent deep dark backdrop
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            if isAditude {
                VStack(spacing: 12) {
                    Text("SPONSORED AD")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(1.5)
                        .padding(.top, 40)
                    
                    // Fixed Medrec frame container (300x250) matching standard ad placement constraints
                    ZStack {
                        AdSimpleWebViewRepresentable(url: adUrl)
                            .frame(width: 300, height: 250)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 10)
                        
                        if circleProgress > 0 {
                            // Guard backdrop protecting click-throughs during initial play durations
                            Color.black.opacity(0.01)
                                .frame(width: 300, height: 250)
                        }
                    }
                    .frame(width: 300, height: 250)
                }
            } else {
                // Full-screen programmatic frame
                ZStack {
                    AdSimpleWebViewRepresentable(url: adUrl)
                        .ignoresSafeArea()
                    
                    if circleProgress > 0 {
                        Color.black.opacity(0.01)
                            .ignoresSafeArea()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            }
            
            // Top Right Controls Area
            VStack {
                HStack {
                    Spacer()
                    
                    if timeRemaining > 0 {
                        // Breathtaking circular ring countdown
                        ZStack {
                            // Circular Background Tracks
                            Circle()
                                .stroke(Color.white.opacity(0.15), lineWidth: 3)
                                .frame(width: 38, height: 38)
                            
                            // Animated Ring
                            Circle()
                                .trim(from: 0.0, to: circleProgress)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.blue, Color.cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                )
                                .frame(width: 38, height: 38)
                                .rotationEffect(Angle(degrees: -90))
                            
                            // Digital Countdown Seconds Label
                            Text("\(timeRemaining)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 20)
                    } else {
                        // Glassmorphic Close Trigger
                        Button(action: {
                            onClose()
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
                        .transition(.scale.combined(with: .opacity))
                        .padding(.trailing, 20)
                        .padding(.top, 20)
                    }
                }
                Spacer()
            }
        }
        .onAppear {
            bootTimer()
        }
    }
    
    private func bootTimer() {
        // 1. Smoothly animate the circle ring progress from 1.0 to 0.0 over 5.0 seconds
        withAnimation(.linear(duration: 5.0)) {
            circleProgress = 0.0
        }
        
        // 2. Decrement the text label seconds counter every second
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            guard timerActive else {
                timer.invalidate()
                return
            }
            
            if timeRemaining > 1 {
                timeRemaining -= 1
            } else {
                timeRemaining = 0
                timerActive = false
                timer.invalidate()
            }
        }
    }
}

// MARK: - Light Simple WebView for Interstitial Ads

struct AdSimpleWebViewRepresentable: UIViewRepresentable {
    let url: String
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.backgroundColor = .white
        webView.isOpaque = true
        webView.scrollView.backgroundColor = .white
        webView.scrollView.isScrollEnabled = false // Interstitial frames are display-only
        
        if let targetUrl = URL(string: url) {
            let request = URLRequest(url: targetUrl)
            webView.load(request)
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Static iframe container
    }
}
