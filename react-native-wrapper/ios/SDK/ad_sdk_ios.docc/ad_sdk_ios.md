# ``ad_sdk_ios``

A high-performance, responsive native Swift SDK for integrating conversational companion mini-games and premium fallback programmatic advertisements.

## Overview

The `ad_sdk_ios` framework provides the complete native codebase for introducing interactive companion widgets into iOS applications. Leveraging SwiftUI and modern Swift Concurrency, it offloads heavy network, tracking, and cache logic from the main UI thread.

### Key Components

The framework is organized into three primary modules:

1. **State Management**: Coordinates authorization sessions, configurations, and thread-safe placement caches.
   - ``MiniGameProvider``
2. **Interactive UI View**: Responsive SwiftUI catalog overlays displaying horizontal carousels (iPhone) or paginated 4-column grids (iPad).
   - ``MiniGameMenu``
   - ``MiniGameTheme``
3. **Data Schemas**: Strongly typed encodable structures for conversational states and analytics tracking.
   - ``Message``
   - ``GameData``

---

## Topics

### Core State Manager

- ``MiniGameProvider``

### Primary Interface

- ``MiniGameMenu``
- ``MiniGameTheme``

### Models & Enums

- ``Message``
- ``GameData``