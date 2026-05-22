//
//  ContentView.swift
//  ad-sdk-ios
//
//  Created by Cesar Rodrigues Nascimento on 22/05/26.
//

import SwiftUI

/// A sample integration demonstrating how a publisher incorporates the Simula SDK.
/// Renders a beautiful conversational AI chat interface with a direct trigger button for the MiniGameMenu.
public struct ContentView: View {
    @StateObject private var provider = MiniGameProvider.shared
    
    @State private var isMenuOpen = false
    @State private var mockMessages: [Message] = [
        Message(role: "user", content: "Hey Luna! I have some free time. What should we do today?"),
        Message(role: "assistant", content: "Hi! We could chat about cooking, tech, or if you're feeling lucky, we could play a fun mini game together! What do you think?")
    ]
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Elegant Background
            Color(hex: "#0b0b0f")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Area
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("Luna AI Companion")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Connection Status Indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(provider.sessionId != nil ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        
                        Text(provider.sessionId != nil ? "Connected" : "Connecting...")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .border(Color.white.opacity(0.04), width: 1)
                
                // Chat Conversation Feed Area
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(mockMessages, id: \.self) { message in
                            HStack(alignment: .top, spacing: 12) {
                                if message.role == "assistant" {
                                    ZStack {
                                        Color.blue.opacity(0.15)
                                        Image(systemName: "face.smiling.fill")
                                            .foregroundColor(.blue)
                                    }
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(message.role == "assistant" ? "Luna" : "You")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white.opacity(0.4))
                                    
                                    Text(message.content)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.white.opacity(0.9))
                                        .padding(12)
                                        .background(message.role == "assistant" ? Color.white.opacity(0.04) : Color.blue.opacity(0.12))
                                        .cornerRadius(16)
                                }
                                
                                if message.role == "user" {
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                
                // Bottom Interactive Placements bar
                VStack(spacing: 12) {
                    // Premium Floating Action Trigger
                    Button(action: {
                        isMenuOpen = true
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 16, weight: .bold))
                            
                            Text("Play Mini Games with Luna")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.blue.opacity(0.3), radius: 10, y: 5)
                    }
                    .padding(.horizontal, 20)
                    
                    // Dummy text input mockup
                    HStack {
                        Text("Type a message to Luna...")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.3))
                        Spacer()
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue.opacity(0.8))
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(14)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
                .border(Color.white.opacity(0.04), width: 1)
            }
            
            // Render the MiniGameMenu SwiftUI Overlay
            MiniGameMenu(
                isOpen: $isMenuOpen,
                charName: "Luna",
                charID: "char_luna_123",
                charImage: "https://example.com/luna-avatar.png",
                messages: mockMessages,
                onGameOpen: { name, desc in
                    print("[Sample App] game opened: \(name)")
                },
                onGameClose: { name in
                    print("[Sample App] game closed: \(name)")
                }
            )
            .environmentObject(provider)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // SDK Initialization with standard credentials
            provider.configure(
                apiKey: "pub_eeee14c661ce47659a289db29364723a",
                devMode: false
            )
        }
    }
}

// MARK: - SwiftUI Preview Provider

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
