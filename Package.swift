import PackageDescription

let package = Package(
    name: "NoctuaSDK",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "NoctuaSDK",
            targets: ["NoctuaSDK"])
    ],
    targets: [
        .target(
            name: "NoctuaSDK",
            dependencies: [
                "FBSDKCoreKit_Basics",
                "FBAEMKit",
                "FBSDKCoreKit"
            ],
            path: "ios/NoctuaSDK/Sources"
        ),
        .binaryTarget(
            name: "FBSDKCoreKit_Basics",
            path: "ios/NoctuaSDK/XCFrameworks/FBSDKCoreKit_Basics.xcframework"
        ),
        .binaryTarget(
            name: "FBAEMKit",
            path: "ios/NoctuaSDK/XCFrameworks/FBAEMKit.xcframework"
        ),
        .binaryTarget(
            name: "FBSDKCoreKit",
            path: "ios/NoctuaSDK/XCFrameworks/FBSDKCoreKit.xcframework"
        )
    ]
)
