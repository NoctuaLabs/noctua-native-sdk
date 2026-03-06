# Noctua Native SDK

## Overview

Multi-platform native SDK for Noctua Games, providing analytics tracking, in-app purchases, account management, and session lifecycle across iOS and Android.

- **Company:** Noctua Games
- **Repo:** `gitlab.com/evosverse/noctua/noctua-sdk-native`
- **iOS Version:** Defined in `NoctuaSDK.podspec` (line 3)
- **Android Version:** Defined in `android/version.txt`

## Repository Structure

```
noctua-sdk-native/
├── NoctuaSDK.podspec           # CocoaPods spec (iOS)
├── Package.swift                # Swift Package Manager manifest
├── .gitlab-ci.yml              # CI/CD pipeline
├── ios/                         # iOS SDK
│   ├── NoctuaSDK/Sources/       # Source code
│   ├── NoctuaSDKTests/          # Unit tests
│   ├── NoctuaSDKExample/        # Example app + Xcode project
│   ├── NoctuaSDKExample.xcworkspace
│   ├── Podfile
│   └── Podfile.lock
└── android/                     # Android SDK
    ├── sdk/                     # Main SDK module
    ├── app/                     # Example app
    └── build.gradle.kts
```

## iOS Architecture

### Layered Architecture

```
Noctua.swift (Public API / Composition Root)
    ↓
Presenter/ (Business logic: TrackerPresenter, StoreKitPresenter, SessionPresenter, AccountPresenter)
    ↓
Service/ (External integrations: StoreKitService, StoreKit1Service, FirebaseService, AdjustService, FacebookService)
    ↓
Repository/ (Data persistence: AccountRepository)
    ↓
Protocol/ (Contracts: StoreKitServiceProtocol, TrackerServiceProtocol, etc.)
Model/ (Data classes: StoreKitModel, NoctuaConfig, Account, NoctuaError)
```

### Key Files

| File | Purpose |
|---|---|
| `Sources/Noctua.swift` | Public API entry point, `initNoctua()`, `buildServices()` factory |
| `Sources/Service/StoreKitService.swift` | StoreKit 2 implementation (async/await) |
| `Sources/Service/StoreKit1Service.swift` | StoreKit 1 implementation (SKPaymentTransactionObserver) |
| `Sources/Presenter/StoreKitPresenter.swift` | StoreKit business logic, bridges callbacks to protocol |
| `Sources/Protocol/StoreKitServiceProtocol.swift` | 10-method interface for IAP operations |
| `Sources/Protocol/StoreKitEventListenerProtocol.swift` | 8 event callbacks for StoreKit |
| `Sources/Model/StoreKitModel.swift` | All StoreKit data models (enums, result classes, config) |
| `Sources/Service/FirebaseService.swift` | Firebase Analytics + Remote Config |
| `Sources/Service/AdjustService.swift` | Adjust attribution + tracking |
| `Sources/Service/FacebookService.swift` | Facebook conversion events |
| `Sources/Service/CurrencyQueryService.swift` | Read-only App Store currency query (SK1) |
| `Sources/Model/NoctuaConfig.swift` | Config structure decoded from `noctuagg.json` |
| `Sources/Platform/IOSLogger.swift` | Logger implementation |

### StoreKit Strategy Pattern

Both StoreKit implementations conform to `StoreKitServiceProtocol`. The factory in `Noctua.buildServices()` selects the implementation based on the `useStoreKit1` parameter:

```swift
// In Noctua.swift buildServices()
if useStoreKit1 {
    storeKitService = StoreKit1Service(config: storeKitConfig, logger: logger)
} else {
    storeKitService = StoreKitService(config: storeKitConfig, logger: logger)
}
```

Default is **StoreKit 1** (backend uses `/verifyReceipt`). `StoreKitPresenter` is agnostic to implementation.

### Protocols

| Protocol | File | Methods |
|---|---|---|
| `StoreKitServiceProtocol` | `Protocol/` | `initialize`, `dispose`, `isReady`, `registerProduct`, `queryProductDetails`, `purchase`, `queryPurchases`, `restorePurchases`, `getProductPurchaseStatus`, `completePurchaseProcessing` |
| `StoreKitEventListener` | `Protocol/` | `onPurchaseCompleted`, `onPurchaseUpdated`, `onProductDetailsLoaded`, `onQueryPurchasesCompleted`, `onRestorePurchasesCompleted`, `onProductPurchaseStatusResult`, `onServerVerificationRequired`, `onStoreKitError` |
| `TrackerServiceProtocol` | `Protocol/` | `trackAdRevenue`, `trackPurchase`, `trackCustomEvent`, `trackCustomEventWithRevenue` |
| `AccountRepositoryProtocol` | `Protocol/` | `putAccount`, `getAllAccounts`, `getSingleAccount`, `deleteAccount` |
| `NoctuaLogger` | `Protocol/` | `debug`, `info`, `warning`, `error` |

### Initialization Flow

1. `Noctua.initNoctua(verifyPurchasesOnServer:useStoreKit1:)` is the entry point
2. Loads config from `noctuagg.json` (bundle resource)
3. `buildServices()` creates all service instances based on config + params
4. Creates presenters: `TrackerPresenter`, `StoreKitPresenter`, `AccountPresenter`, `SessionPresenter`
5. Stored as static properties on `Noctua`

### Testing Support

The `Noctua` class provides `#if DEBUG` methods for testing:
- `resetForTesting()` — nils all static properties
- `configureForTesting(tracker:storeKit:account:session:)` — injects mock presenters

## iOS Build & Test

### Prerequisites
```bash
# Install pods (required after adding/removing source files)
cd ios && LANG=en_US.UTF-8 pod install
```

### Run Tests
```bash
cd /path/to/noctua-sdk-native
xcodebuild test \
  -workspace ios/NoctuaSDKExample.xcworkspace \
  -scheme NoctuaSDKTests \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'
```

### Pod Lint
```bash
LANG=en_US.UTF-8 pod lib lint NoctuaSDK.podspec --allow-warnings
```

**Important:** CocoaPods requires UTF-8 encoding. Always prefix `pod` commands with `LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8` if you get encoding errors.

### Adding New Source Files

The Pods project uses a source glob (`Sources/**/*.swift`), so new files in `Sources/` are auto-discovered after `pod install`. However, **test files** must be manually added to the Xcode project:

1. Add `PBXFileReference` entry in `project.pbxproj`
2. Add `PBXBuildFile` entry linking to `NoctuaSDKTests` Sources build phase
3. Add to the appropriate `PBXGroup` (Mocks/, Service/, etc.)

Or run `pod install` for source files and manually add test files to the project.

## iOS Test Structure

```
NoctuaSDKTests/
├── Helpers/TestHelpers.swift          # TestConfigFactory
├── Mocks/                             # Mock implementations
│   ├── MockStoreKitService.swift
│   ├── MockTrackerService.swift
│   ├── MockAccountRepository.swift
│   ├── MockFirebaseQueryService.swift
│   ├── MockAdjustSpecific.swift
│   ├── MockNoctuaLogger.swift
│   ├── MockNoctuaInternalService.swift
│   ├── MockPaymentQueue.swift         # PaymentQueueProtocol mock
│   └── MockSKPaymentTransaction.swift # SKPaymentTransaction subclass
├── Model/                             # 4 test files
├── Presenter/                         # 4 test files
├── Service/                           # StoreKit1ServiceTests, CurrencyQueryServiceTests
└── NoctuaPublicAPITests.swift         # Public API integration tests
```

### Mock Patterns

- **Protocol mocks** track calls with arrays (e.g., `purchaseCalls: [String]`) and flags (e.g., `initializeCalled = false`)
- **MockNoctuaLogger** captures messages by level (`debugMessages`, `infoMessages`, etc.)
- **MockPaymentQueue** implements `PaymentQueueProtocol` for StoreKit1Service DI
- **MockSKPaymentTransaction** overrides read-only properties with settable stored props

## Android Build & Test

```bash
cd android
./gradlew :sdk:test           # Unit tests
./gradlew :sdk:connectedTest  # Instrumentation tests
```

## Logging Convention

**iOS:** Always use the `NoctuaLogger` protocol:
```swift
let logger = IOSLogger(category: "MyService")
logger.debug("message")
logger.info("message")
logger.warning("message")
logger.error("message")
```

**Android:** Uses Android `Log` framework.

## Configuration

The SDK reads `noctuagg.json` from the app bundle. Structure:
```json
{
    "clientId": "required-string",
    "gameId": 123,
    "noctua": { "iapDisabled": false },
    "adjust": { "ios": { ... } },
    "firebase": { "ios": { ... } },
    "facebook": { "ios": { ... } }
}
```

`useStoreKit1` is **not** in config — it's a parameter on `initNoctua()`.

## Dependencies (iOS)

Managed via CocoaPods subspecs in `NoctuaSDK.podspec`:
- **Core:** StoreKit, WebKit, Security, AdSupport, AppTrackingTransparency
- **Adjust:** `Adjust` (~5.4.4)
- **Firebase:** Analytics, Crashlytics, Messaging, RemoteConfig (~12.2.0)
- **Facebook:** Static XCFrameworks (v18.0.0)
- **NoctuaInternalSDK:** Pre-built XCFramework (~0.15.0)

Source glob: `ios/NoctuaSDK/Sources/**/*.{h,m,swift}` — new source files auto-discovered.

## Git Conventions

- **Branch naming:** `feat/feature-name`, `fix/bug-name`, `chore/task-name`
- **Commit style:** Conventional commits (`feat:`, `fix:`, `chore:`)
- **Tags:** `ios-sdk-v{VERSION}`, `android-sdk-v{VERSION}`
- **CI triggers:** Merge to `main` with relevant file changes

## Unity SDK Integration

The native iOS SDK is consumed by the Unity SDK via CocoaPods and a C bridge:

```
Unity C# (IosPlugin.cs) → P/Invoke [DllImport("__Internal")]
    → NoctuaInterop.m (Obj-C bridge)
    → Noctua.swift (native SDK)
```

The Unity bridge files live in the Unity SDK repo (`noctua-sdk-unity`), not here. Changes to `Noctua.swift`'s public API may require corresponding updates to `NoctuaInterop.m/h` and `IosPlugin.cs` in the Unity repo.
