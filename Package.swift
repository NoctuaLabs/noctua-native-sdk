// swift-tools-version: 6.1
// version: "0.2.0"

import PackageDescription

let package = Package(
    name: "NoctuaSDK",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "NoctuaSDK",
            targets: ["NoctuaSDK"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/adjust/ios_sdk.git", .upToNextMajor(from: "5.4.1")),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", .upToNextMajor(from: "11.6.0")),
        .package(url: "https://github.com/facebook/facebook-ios-sdk.git", .upToNextMajor(from: "18.0.0"))
    ],
    targets: [
        // Main target
        .target(
            name: "NoctuaSDK",
            dependencies: [
                .product(name: "AdjustSdk", package: "ios_sdk", condition: .when(platforms: [.iOS])),
                .product(name: "AdjustWebBridge", package: "ios_sdk", condition: .when(platforms: [.iOS])),

                .product(name: "FirebaseAnalytics",  package: "firebase-ios-sdk", condition: .when(platforms: [.iOS])),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk", condition: .when(platforms: [.iOS])),
                .product(name: "FirebaseMessaging",  package: "firebase-ios-sdk", condition: .when(platforms: [.iOS])),
                .product(name: "FirebaseRemoteConfig",  package: "firebase-ios-sdk", condition: .when(platforms: [.iOS])),
                
                .product(name: "FacebookAEM", package: "facebook-ios-sdk", condition: .when(platforms: [.iOS])),
                .product(name: "FacebookBasics", package: "facebook-ios-sdk", condition: .when(platforms: [.iOS])),
                .product(name: "FacebookCore", package: "facebook-ios-sdk", condition: .when(platforms: [.iOS])),
                .product(name: "FacebookLogin", package: "facebook-ios-sdk", condition: .when(platforms: [.iOS])),
                .product(name: "FacebookShare", package: "facebook-ios-sdk", condition: .when(platforms: [.iOS])),
                .product(name: "FacebookGamingServices", package: "facebook-ios-sdk", condition: .when(platforms: [.iOS]))
            ],
            path: "NoctuaSDK/Sources"
        ),
    ]
)
