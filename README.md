# Simula MiniGame SDK for iOS (Native Swift)

The **Simula MiniGame SDK** is a high-performance, native Swift library for iOS 16+ that allows publishers to seamlessly integrate conversational mini-games and premium programmatic advertisements into their applications. 

Designed strictly with **SwiftUI** and **Swift Concurrency (`async/await`)**, the SDK delivers a visually stunning, responsive user experience without ever blocking the main thread or causing UI jitter.

---

## Key Features

* **⚡ Ultra-Performance Architecture:** Entirely decoupled UI and state logic. Background tasks, network requests, and analytics reporting are safely offloaded using modern Swift Concurrency.
* **📱 Adaptive Layout Engine:** Fully responsive design adapting automatically to iOS size classes:
  * **Compact Class (iPhones):** A swipeable horizontal poster-card list utilizing high-fidelity press-scaling animations and native gesture handling.
  * **Regular Class (iPads / Landscape):** A horizontally paginated **4-column grid layout per page** with dynamic aspect-ratio scaling and a custom blue page indicator dot system.
* **🔒 Thread-Safe SDK Cache:** Protected by recursive locks (`NSRecursiveLock`), avoiding data races across background tasks and concurrent threads.
* **🎨 Fully Customizable Themes:** Deep control over colors, gradients, titles, fonts, and banners matching your app's brand aesthetics.
* **🌐 Web-Native Bridging:** Implements `WKWebView` wrappers with bidirectional JavaScript message bridges to report ad servers and load gameplay frames instantly.
* **📈 In-Game Fallback Ads & Countdown Ring:** Displays interactive sponsored ads with beautiful 5-second circular vector countdown timer overlays upon game dismissal.

---

## Core Architecture Diagram

The SDK follows an isolated, single-responsibility layered model:

```mermaid
graph TD
    subgraph UI ["UI Layer (Main Thread)"]
        Menu[MiniGameMenu SwiftUI]
        CarouselView[Horizontal Poster View]
        GridView[Paginated 4-Column Grid]
        GWeb[Game WebView Representable]
        AdWeb[Ad WebView & Vector Timer]
    end

    subgraph State ["State & Logic Layer (MainActor / Lock-Safe)"]
        Provider[MiniGameProvider Observable]
        Cache[MiniGameCache NSRecursiveLock]
    end

    subgraph Network ["Network Layer (Background Thread)"]
        API[APIClient URLSession async/await]
    end

    Menu -->|State Updates| Provider
    Provider -->|State Mutations| Cache
    Provider -->|API Calls| API
    API -->|Fetch Catalog & Ad Configs| Provider
    GWeb -->|WKScriptMessageHandler| Provider
```

---

## Repository & Folder Structure

To support clean maintenance, isolation, and integration of the native SDK and the React Native wrapper, the codebase is structured into three distinct domains:

```
ad-sdk-ios/
├── ios-sdk/                          # NATIVE iOS SDK BUILD & TESTS
│   ├── ad-sdk-ios.xcodeproj/         # Native Xcode framework project
│   ├── ad-sdk-iosTests/              # Native Swift thread-safety and decoder tests
│   └── SampleApp/                    # Native iOS SwiftUI Showcase/Sample App
│
├── react-native-wrapper/             # REACT NATIVE SDK WRAPPER (NPM PACKAGE)
│   ├── package.json                  # NPM Package manifest
│   ├── simula-ad-sdk.podspec         # Podspec for autolinking recursively under ios/
│   ├── src/
│   │   └── index.tsx                 # JS/TS interface layer
│   └── ios/                          # NATIVE SOURCE CONSOLIDATION
│       ├── SDK/                      # Pure native Swift SDK source files (APIClient, views, etc.)
│       └── Bridge/                   # React Native ObjC/Swift bridge modules and managers
│
└── RNSampleApp/                      # CONSUMER SHOWCASE REACT NATIVE APP
    ├── package.json                  # Links to "simula-ad-sdk": "file:../react-native-wrapper"
    └── metro.config.js               # Watch config resolving dependencies cleanly
```

---

## Installation

### Manual Integration
1. Drag the compiled `ad_sdk_ios.framework` into your Xcode project.
2. Select your Target, navigate to **General**, and add the framework to **Frameworks, Libraries, and Embedded Content**.
3. Set the embed type to **Embed & Sign**.

---

## Quick Start Guide

### 1. Initialize the SDK
Initialize and configure the SDK provider on your app launch or within your main content views. The configuration maps your specific publisher key and defaults domain bindings (like `"coolaigames.com"`) for Aditude slots:

```swift
import SwiftUI
import ad_sdk_ios

@main
struct CompanionApp: App {
    @StateObject private var provider = MiniGameProvider.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(provider)
                .onAppear {
                    // Initialize with your API key
                    provider.configure(
                        apiKey: "pub_eeee14c661ce47659a289db29364723a",
                        devMode: false
                    )
                }
        }
    }
}
```

### 2. Present the MiniGameMenu (SwiftUI)
Bind a Boolean state to the catalog drawer overlay and inject the companion parameters. The SDK handles catalog fetching, session tracking, and responsive layout scaling automatically:

```swift
import SwiftUI
import ad_sdk_ios

struct ChatView: View {
    @EnvironmentObject private var provider: MiniGameProvider
    @State private var isMenuOpen = false
    
    var body: some View {
        ZStack {
            // Your Primary Conversation UI
            VStack {
                Button(action: { isMenuOpen = true }) {
                    HStack {
                        Image(systemName: "gamecontroller.fill")
                        Text("Play Games with Luna")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            
            // Full-screen MiniGame Responsive Drawer Overlay
            MiniGameMenu(
                isOpen: $isMenuOpen,
                charName: "Luna",
                charID: "char_luna_101",
                charImage: "https://example.com/luna-avatar.png",
                messages: [
                    Message(role: "user", content: "Hey Luna, let's play!"),
                    Message(role: "assistant", content: "Awesome! Click below to start.")
                ],
                onGameOpen: { gameName, description in
                    print("Started playing: \(gameName)")
                },
                onGameClose: { gameName in
                    print("Dismissed game: \(gameName)")
                }
            )
        }
    }
}
```

### 3. UIKit Integration
For traditional UIKit architectures, wrap the `MiniGameMenu` view inside a standard `UIHostingController` and present it dynamically over your view controller:

```swift
import UIKit
import SwiftUI
import ad_sdk_ios

class ChatViewController: UIViewController {
    private let provider = MiniGameProvider.shared
    private var isMenuOpen = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure SDK
        provider.configure(
            apiKey: "pub_eeee14c661ce47659a289db29364723a",
            devMode: false
        )
    }
    
    @objc func openMiniGamesMenu() {
        self.isMenuOpen = true
        let menuBinding = Binding<Bool>(
            get: { self.isMenuOpen },
            set: { self.isMenuOpen = $0 }
        )
        
        // Build the Menu view tree
        let menuView = MiniGameMenu(
            isOpen: menuBinding,
            charName: "Luna",
            charID: "char_luna_101",
            charImage: "https://example.com/luna-avatar.png"
        ).environmentObject(provider)
        
        let hostingController = UIHostingController(rootView: menuView)
        hostingController.modalPresentationStyle = .overFullScreen
        hostingController.view.backgroundColor = .clear
        
        present(hostingController, animated: true)
    }
}
```

---

## Detailed Customization & Theme Configurations

Use the `MiniGameTheme` struct during initialization to customize the overlay. The layout supports full hex-color formatting and maps theme elements dynamically:

```swift
var customTheme = MiniGameTheme(
    accentColor: "#00d2ff",         // Glowing cyan theme accent (buttons, indicators)
    backgroundColor: "#07070a",     // Solid dark backdrop container background
    titleFontColor: "#ffffff",      // Main text and header color
    cardBorderColor: "#1d1d26"      // Sleek subtle card borders
)

// Pass to the Menu Overlay
MiniGameMenu(
    isOpen: $isMenuOpen,
    charName: "Luna",
    charID: "char_luna_101",
    charImage: "https://example.com/luna-avatar.png",
    theme: customTheme
)
```

---

## Thread Safety and Performance Audit

To fulfill strict production SDK mandates, the library strictly guards system resources:
1. **Zero Main-Thread Blocks:** Network-bound API parsing, configuration downloads, and tracking posts utilize URLSession async pipelines executing completely off the UI thread.
2. **Lock-Protected Data States:** State cache elements are isolated through recursive locking:
   ```swift
   private let lock = NSRecursiveLock()
   
   func cacheAd(adId: String, iframeUrl: String) {
       lock.lock()
       defer { lock.unlock() }
       adCache[adId] = iframeUrl
   }
   ```
3. **Optimized Render Cycles:** Image rendering uses standard lazy asynchronous blocks (`AsyncImage`) caching remote media, avoiding catalog rendering lag.
4. **React Native Bridge Touch Resolution:** Bypasses React Native's standard `RCTTouchHandler` filters by presenting the catalog menu and game webviews modally (`.overFullScreen`) from a native UIKit window scene. This ensures 100% responsive snap carousel dragging and webview click actions with zero gesture freezes.
5. **Bridge `deinit` Unmount Safeguard:** Implements an explicit `deinit` destructor inside the native view manager. If a publisher abruptly unmounts the JS component (e.g., `{isOpen && <MiniGameMenu />}`), the Swift runtime automatically triggers view-controller dismissal on the main actor, preventing visual overlays from dangling or leaking memory.
6. **Zero-Overhead JS Mounting:** The React Native TypeScript layer returns a `null` render state immediately when `isOpen` is `false`. This avoids mounting, sizing, or maintaining inactive native component overlay views in the RN flexbox layout tree.

---

## React Native Integration Guide

The **Simula MiniGame SDK** is fully compatible with React Native applications through the modern, local library bridge wrapper `react-native-wrapper`. This bridge abstracts the native Swift layouts under elegant TypeScript interfaces matching your web-native workflows.

### 1. Installation

#### Add the Dependency
Map the bridge wrapper locally inside your React Native application’s `package.json`:

```json
"dependencies": {
  "simula-ad-sdk": "file:../react-native-wrapper"
}
```

Then run the installation within the root of your React Native project:

```bash
npm install
```

#### Link iOS Native Frameworks
Navigate to your React Native project’s `ios/` folder and execute CocoaPods installation. The bridge `.podspec` automatically resolves and compiles the local wrapper bridge and native Swift SDK files recursively:

```bash
cd ios
pod install
```

---

### 2. React Native Quick Start Guide

#### Step 1: Wrap your App in `<MiniGameProvider>`
Initialize the provider at the absolute root of your React Native application (e.g., `App.tsx`) to configure credentials and session lifetimes:

```tsx
import React from 'react';
import { MiniGameProvider } from 'simula-ad-sdk';
import { MainScreen } from './src/MainScreen';

export default function App() {
  return (
    <MiniGameProvider
      apiKey="pub_eeee14c661ce47659a289db29364723a"
      primaryUserID="user_rn_showcase_101"
      hasPrivacyConsent={true}
      devMode={false}      // Set true during offline simulator mocks
      appDomain="coolaigames.com"
    >
      <MainScreen />
    </MiniGameProvider>
  );
}
```

#### Step 2: Render the `<MiniGameMenu>` Overlay
Import the responsive menu overlay, bind its active open state, and receive native synthetic callbacks in JavaScript:

```tsx
import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { MiniGameMenu } from 'simula-ad-sdk';

export function MainScreen() {
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  return (
    <View style={styles.container}>
      <TouchableOpacity 
        style={styles.button} 
        onPress={() => setIsMenuOpen(true)}
      >
        <Text style={styles.buttonText}>Play with Luna</Text>
      </TouchableOpacity>

      <MiniGameMenu
        isOpen={isMenuOpen}
        charName="Luna"
        charID="char_luna_101"
        charImage="https://example.com/avatar.png"
        messages={[
          { role: 'user', content: 'Hey Luna, let\'s play some games!' },
          { role: 'assistant', content: 'I have some awesome mini-games ready. Let\'s go!' }
        ]}
        theme={{
          backgroundColor: '#07070a', // Custom premium dark backdrop
          accentColor: '#00d2ff',     // Neon cyan glow indicators
          iconCornerRadius: 16
        }}
        onImpression={(e) => console.log('Catalog opened, menuId:', e.menuId)}
        onGameOpen={(e) => console.log('Started playing:', e.gameName)}
        onGameClose={(e) => {
          console.log('Dismissed game:', e.gameName);
          // VERY IMPORTANT: Synchronize your React state when the menu overlay is closed!
          if (e.gameName === 'menu') {
            setIsMenuOpen(false);
          }
        }}
        onDestinationOpen={(e) => {
          console.log(`Opened in-app destination: Type: ${e.destinationType}, Target: ${e.target}`);
        }}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#050508' },
  button: { paddingVertical: 14, paddingHorizontal: 28, backgroundColor: '#00d2ff', borderRadius: 12 },
  buttonText: { color: '#000000', fontSize: 16, fontWeight: 'bold' }
});
```

---

### 3. Developer Event Handlers and Callback API

The React Native wrapper maps high-performance Objective-C synthetic blocks (`RCTDirectEventBlock`) into clean direct JS/TS callbacks containing structured event payloads:

| Callback Prop | Event Payload | Trigger Description |
|---|---|---|
| `onImpression` | `{ menuId: string }` | Dispatched immediately when the minigames catalog is fetched and displayed. |
| `onGameOpen` | `{ gameName: string, description: string }` | Dispatched when the user taps a mini-game and its active gameplay webview begins loading. |
| `onGameClose` | `{ gameName: string }` | Dispatched when a mini-game view is dismissed (returns the active game name) or when the menu catalog drawer itself is closed (`gameName: "menu"`). |
| `onDestinationOpen` | `{ destinationType: "app" \| "web", target: string }` | Dispatched when an advertiser destination is intercepted (e.g. in-app Safari `SFSafariViewController` or in-app App Store `SKStoreProductViewController`). |

---

### 4. Testing & Verification

To verify that changes are fully integrated and do not cause regressions across the JS, native module, or SwiftUI layers, you can execute the following verification suites:

#### Run React Native Unit Tests (Jest)
The React Native Jest suite validates the JS/TS layer, default properties, and the bridge callback event unpacking logic:
```bash
cd RNSampleApp
npm test
```

#### Run the Showcase Sample App in iOS Simulator
1. Install JS dependencies:
   ```bash
   cd RNSampleApp
   npm install
   ```
2. Link and configure native Pods:
   ```bash
   cd ios
   pod install
   ```
3. Boot the application on your simulator:
   ```bash
   cd ..
   npx react-native run-ios
   ```

---

## License & Support
For SDK support, updates, or API credentials, contact the platform operations team or check your publisher portal dashboard.
