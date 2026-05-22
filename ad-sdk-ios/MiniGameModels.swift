//
//  MiniGameModels.swift
//  ad-sdk-ios
//
//  Created by Cesar Rodrigues Nascimento on 22/05/26.
//

import Foundation

/// Represents a conversational chat message for targeting contextual ads.
public struct Message: Codable, Hashable {
    public let role: String
    public let content: String

    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

/// Represents individual game metadata fetched from the mini games catalog.
public struct GameData: Codable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let iconUrl: String
    public let description: String
    public let iconFallback: String?
    public let gifCover: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case iconUrl = "icon"
        case description
        case iconFallback
        case gifCover = "gif_cover"
    }

    public init(id: String, name: String, iconUrl: String, description: String, iconFallback: String? = nil, gifCover: String? = nil) {
        self.id = id
        self.name = name
        self.iconUrl = iconUrl
        self.description = description
        self.iconFallback = iconFallback
        self.gifCover = gifCover
    }
}

/// Style settings to customize the appearance of the mini game menu.
public struct MiniGameTheme: Codable, Hashable {
    public var backgroundColor: String?
    public var headerColor: String?
    public var borderColor: String?
    public var titleFont: String?
    public var secondaryFont: String?
    public var titleFontColor: String?
    public var secondaryFontColor: String?
    public var iconCornerRadius: Int?
    public var accentColor: String?
    public var playableHeight: String? // Can be percentage e.g., "80%" or pixel e.g. "500"
    public var playableBorderColor: String?

    public init(
        backgroundColor: String? = nil,
        headerColor: String? = nil,
        borderColor: String? = nil,
        titleFont: String? = nil,
        secondaryFont: String? = nil,
        titleFontColor: String? = nil,
        secondaryFontColor: String? = nil,
        iconCornerRadius: Int? = nil,
        accentColor: String? = nil,
        playableHeight: String? = nil,
        playableBorderColor: String? = nil
    ) {
        self.backgroundColor = backgroundColor
        self.headerColor = headerColor
        self.borderColor = borderColor
        self.titleFont = titleFont
        self.secondaryFont = secondaryFont
        self.titleFontColor = titleFontColor
        self.secondaryFontColor = secondaryFontColor
        self.iconCornerRadius = iconCornerRadius
        self.accentColor = accentColor
        self.playableHeight = playableHeight
        self.playableBorderColor = playableBorderColor
    }
}

/// Core ad delivery object.
public struct AdData: Codable, Identifiable, Hashable {
    public var id: String
    public let format: String
    public let iframeUrl: String?
    public let html: String?

    public init(id: String, format: String, iframeUrl: String? = nil, html: String? = nil) {
        self.id = id
        self.format = format
        self.iframeUrl = iframeUrl
        self.html = html
    }
}

/// Mapping specifications for specific Aditude ad placement units.
public struct AditudeSlotMapping: Codable, Hashable {
    public let divId: String
    public let devices: [String]
    public let adUnitPath: String
    public let sizes: [String: [[Int]]]?

    enum CodingKeys: String, CodingKey {
        case divId = "div_id"
        case devices
        case adUnitPath = "ad_unit_path"
        case sizes
    }
}

/// Complete configuration wrapper for Aditude cloud wraps.
public struct AditudeConfig: Codable, Hashable {
    public let domain: String
    public let enabled: Bool
    public let scriptUrl: String
    public let mappings: [AditudeSlotMapping]

    enum CodingKeys: String, CodingKey {
        case domain
        case enabled
        case scriptUrl = "script_url"
        case mappings
    }
}

// MARK: - API Payloads

/// Internal wrapper for the Catalog endpoint response.
struct CatalogResponsePayload: Codable {
    let menuId: String?
    let catalog: [GameData]?
    let data: [GameData]?

    enum CodingKeys: String, CodingKey {
        case menuId = "menu_id"
        case catalog
        case data
    }
}

/// Payload sent to initialize a mini game.
struct InitMinigameRequestPayload: Codable {
    let gameType: String
    let sessionId: String
    let convId: String?
    let entryPoint: String?
    let currencyMode: Bool
    let w: Int
    let h: Int
    let charId: String?
    let charName: String?
    let charImage: String?
    let charDesc: String?
    let messages: [Message]?
    let delegateChar: Bool
    let menuId: String?

    enum CodingKeys: String, CodingKey {
        case gameType = "game_type"
        case sessionId = "session_id"
        case convId = "conv_id"
        case entryPoint = "entry_point"
        case currencyMode = "currency_mode"
        case w, h
        case charId = "char_id"
        case charName = "char_name"
        case charImage = "char_image"
        case charDesc = "char_desc"
        case messages
        case delegateChar = "delegate_char"
        case menuId = "menu_id"
    }
}

/// Response returned when initiating a mini game.
struct MinigameResponsePayload: Codable {
    let adType: String
    let adInserted: Bool
    let adResponse: AdResponseInner

    enum CodingKeys: String, CodingKey {
        case adType
        case adInserted
        case adResponse
    }
}

struct AdResponseInner: Codable {
    let adId: String?
    let serveId: String?
    let iframeUrl: String?

    enum CodingKeys: String, CodingKey {
        case adId = "ad_id"
        case serveId = "serve_id"
        case iframeUrl = "iframe_url"
    }
}

/// Payload sent to report fallback/interstitial ad events.
struct AdInterstitialReportPayload: Codable {
    let sessionId: String
    let adSource: String
    let renderedFormat: String?

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case adSource = "ad_source"
        case renderedFormat = "rendered_format"
    }
}
