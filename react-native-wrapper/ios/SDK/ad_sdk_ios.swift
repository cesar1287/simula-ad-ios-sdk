//
//  ad_sdk_ios.swift
//  ad-sdk-ios
//
//  Created by Cesar Rodrigues Nascimento on 22/05/26.
//

import Foundation

/**
  Simula iOS SDK
  
  An asynchronous, high-performance contextual advertising SDK for iOS apps.
  Features:
  - Contextual AI ad delivery
  - Native SwiftUI implementation (MiniGameMenu & MiniGameProvider)
  - Offloaded background thread execution to prevent main thread blocking
  - Size-class responsive layouts adapting carousel (Compact) vs grid (Regular) trait collections
  
  Use:
  - Initialize the provider: `MiniGameProvider.shared.configure(apiKey: "pub_...")`
  - Render the catalog overlay in SwiftUI: `MiniGameMenu(isOpen: $isOpen, charName: "Luna", ...)`
*/
public struct SimulaSDK {
    public static let version = "1.0.0"
}
