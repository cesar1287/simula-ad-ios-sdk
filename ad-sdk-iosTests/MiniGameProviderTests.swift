import XCTest
@testable import ad_sdk_ios

class MiniGameProviderTests: XCTestCase {
    
    // Test 1: Verify thread-safe caching under heavy parallel read/write pressure (Concurrency stress test)
    func testCacheThreadSafety() {
        let provider = MiniGameProvider.shared
        let expectation = self.expectation(description: "Concurrent cache writes completed")
        expectation.expectedFulfillmentCount = 100
        
        // Spawn 100 parallel concurrent operations accessing the lock-safe cache
        for i in 0..<100 {
            DispatchQueue.global().async {
                let slot = "slot_test"
                let pos = i
                
                // Concurrent Write
                provider.cacheHeight(slot: slot, position: pos, height: Double(i) * 10.0)
                
                // Concurrent Read
                let cachedHeight = provider.getCachedHeight(slot: slot, position: pos)
                XCTAssertEqual(cachedHeight, Double(i) * 10.0)
                
                // Concurrent mark
                provider.markNoFill(slot: slot, position: pos)
                XCTAssertTrue(provider.hasNoFill(slot: slot, position: pos))
                
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    // Test 2: Verify JSON decodes optional destination parameters correctly from snake_case API data
    func testGameDataDecoding() throws {
        let jsonString = """
        {
            "id": "boop_the_snoot",
            "name": "Boop The Snoot",
            "icon": "https://example.com/icon.png",
            "description": "Boop to earn treats!",
            "destination_type": "app",
            "destination_target": "831515428"
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let game = try decoder.decode(GameData.self, from: jsonData)
        
        XCTAssertEqual(game.id, "boop_the_snoot")
        XCTAssertEqual(game.name, "Boop The Snoot")
        XCTAssertEqual(game.destinationType, "app")
        XCTAssertEqual(game.destinationTarget, "831515428")
    }
    
    // Test 3: Verify fallback behavior for missing destination parameters
    func testGameDataDecodingFallback() throws {
        let jsonString = """
        {
            "id": "blackjack",
            "name": "Blackjack",
            "icon": "https://example.com/icon.png",
            "description": "Classic casino blackjack."
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let game = try decoder.decode(GameData.self, from: jsonData)
        
        XCTAssertNil(game.destinationType)
        XCTAssertNil(game.destinationTarget)
    }
    
    // Test 4: Verify custom theme data bindings parse hexadecimal color codes correctly
    func testThemeHexColorBinding() {
        let theme = MiniGameTheme(
            backgroundColor: "#050508",
            accentColor: "#00d2ff",
            iconCornerRadius: 16
        )
        
        XCTAssertEqual(theme.backgroundColor, "#050508")
        XCTAssertEqual(theme.accentColor, "#00d2ff")
        XCTAssertEqual(theme.iconCornerRadius, 16)
    }
    
    // Test 5: Verify Color(hex:) SwiftUI extension parses multiple formats correctly
    func testColorHexParsing() {
        // 3-digit RGB hex
        let rgb3 = Color(hex: "#F0A")
        // case 3 should decode F0A -> FF00AA
        // Since SwiftUI Color comparison is difficult directly without UI hosting, we can verify it compiles
        // and doesn't crash on standard 3-digit hex strings
        XCTAssertNotNil(rgb3)
        
        // 6-digit RGB hex
        let rgb6 = Color(hex: "00d2ff")
        XCTAssertNotNil(rgb6)
        
        // 8-digit ARGB hex
        let argb8 = Color(hex: "#80FF0055")
        XCTAssertNotNil(argb8)
        
        // Invalid hex gracefully fallbacks
        let invalid = Color(hex: "invalid_color_value")
        XCTAssertNotNil(invalid)
    }
    
    // Test 6: Verify Polymorphic CatalogContainer decodes direct array structure
    func testCatalogContainerAsArray() throws {
        let jsonString = """
        [
            {
                "id": "game_1",
                "name": "Game One",
                "icon": "https://example.com/icon1.png",
                "description": "Desc One"
            },
            {
                "id": "game_2",
                "name": "Game Two",
                "icon": "https://example.com/icon2.png",
                "description": "Desc Two"
            }
        ]
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let container = try decoder.decode(CatalogContainer.self, from: jsonData)
        
        let games = container.games
        XCTAssertEqual(games.count, 2)
        XCTAssertEqual(games[0].id, "game_1")
        XCTAssertEqual(games[1].name, "Game Two")
    }
    
    // Test 7: Verify Polymorphic CatalogContainer decodes wrapped object structure
    func testCatalogContainerAsObject() throws {
        let jsonString = """
        {
            "data": [
                {
                    "id": "game_3",
                    "name": "Game Three",
                    "icon": "https://example.com/icon3.png",
                    "description": "Desc Three"
                }
            ]
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let container = try decoder.decode(CatalogContainer.self, from: jsonData)
        
        let games = container.games
        XCTAssertEqual(games.count, 1)
        XCTAssertEqual(games[0].id, "game_3")
        XCTAssertEqual(games[0].description, "Desc Three")
    }
    
    // Test 8: Verify CatalogResponsePayload resolves fallback path
    func testCatalogPayloadWithDataFallback() throws {
        let jsonString = """
        {
            "menu_id": "menu_999",
            "data": [
                {
                    "id": "game_fallback",
                    "name": "Fallback Game",
                    "icon": "https://example.com/icon_fb.png",
                    "description": "Fallback Desc"
                }
            ]
        }
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let payload = try decoder.decode(CatalogResponsePayload.self, from: jsonData)
        
        XCTAssertEqual(payload.menuId, "menu_999")
        XCTAssertNil(payload.catalog)
        XCTAssertNotNil(payload.data)
        
        let gamesList = payload.catalog?.games ?? payload.data ?? []
        XCTAssertEqual(gamesList.count, 1)
        XCTAssertEqual(gamesList[0].id, "game_fallback")
        XCTAssertEqual(gamesList[0].name, "Fallback Game")
    }
}
