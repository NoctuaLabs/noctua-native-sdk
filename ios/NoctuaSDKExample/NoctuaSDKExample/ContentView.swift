//
//  ContentView.swift
//  NoctuaSDKExample
//
//  Created by SDK Dev on 01/08/24.
//

import SwiftUI
import os
import NoctuaSDK

// MARK: - Default Test Products

let defaultTestProducts: [(String, ConsumableType)] = [
    ("noctua.sub.1", .subscription),
    ("noctua.sub.2", .subscription),
    ("noctua.sub.3", .subscription),
    ("noctua.sdktest.ios.pack1", .consumable),
    ("noctua.unitysdktest.noads.banner", .nonConsumable),
]

struct ContentView: View {
    @StateObject private var viewModel = AccountViewModel()
    let gameId: Int64
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ContentView")

    // StoreKit state
    @State private var storeKitProducts: [NoctuaProductDetails] = []
    @State private var storeKitPurchases: [NoctuaPurchaseResult] = []
    @State private var storeKitError: String? = nil
    @State private var productPurchaseStatus: NoctuaProductPurchaseStatus? = nil
    @State private var statusMessage: String = ""
    @State private var storeKitInitialized: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SectionCard(title: "Tracking", icon: "chart.bar", iconColor: .blue) {
                    TrackingSection(logger: logger)
                }

                SectionCard(title: "StoreKit", icon: "cart", iconColor: .green) {
                    StoreKitSection(
                        products: $storeKitProducts,
                        purchases: $storeKitPurchases,
                        storeKitError: $storeKitError,
                        productPurchaseStatus: $productPurchaseStatus,
                        statusMessage: $statusMessage,
                        defaultProducts: defaultTestProducts,
                        logger: logger
                    )
                }

                SectionCard(title: "Accounts", icon: "person.2", iconColor: .orange) {
                    AccountSection(viewModel: viewModel, gameId: gameId)
                }

                SectionCard(title: "Other", icon: "wrench", iconColor: .gray, expandedByDefault: false) {
                    OtherSection(logger: logger)
                }

                // Status Message Bar
                if !statusMessage.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text(statusMessage)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            .padding()
        }
        .background(Color(.secondarySystemGroupedBackground))
        .onAppear {
            initializeStoreKit()
        }
    }

    // MARK: - StoreKit Initialization

    private func initializeStoreKit() {
        guard !storeKitInitialized else { return }

        Noctua.initializeStoreKit(
            onPurchaseCompleted: { result in
                logger.debug("Purchase completed: \(result.productId), success: \(result.success)")
                statusMessage = "Purchase \(result.success ? "succeeded" : "failed"): \(result.productId) - \(result.message)"
                if result.success {
                    storeKitPurchases.append(result)
                }
            },
            onPurchaseUpdated: { result in
                logger.debug("Purchase updated: \(result.productId)")
                if let idx = storeKitPurchases.firstIndex(where: { $0.purchaseToken == result.purchaseToken }) {
                    storeKitPurchases[idx] = result
                } else {
                    storeKitPurchases.append(result)
                }
            },
            onProductDetailsLoaded: { products in
                logger.debug("Products loaded: \(products.count)")
                storeKitProducts = products
                statusMessage = "Loaded \(products.count) products"
            },
            onQueryPurchasesCompleted: { purchases in
                logger.debug("Purchases queried: \(purchases.count)")
                storeKitPurchases = purchases
                statusMessage = "Found \(purchases.count) purchases"
            },
            onRestorePurchasesCompleted: { purchases in
                logger.debug("Purchases restored: \(purchases.count)")
                storeKitPurchases = purchases
                statusMessage = "Restored \(purchases.count) purchases"
            },
            onProductPurchaseStatusResult: { status in
                logger.debug("Purchase status: \(status.productId) isPurchased=\(status.isPurchased)")
                productPurchaseStatus = status
                statusMessage = "Status for \(status.productId): \(status.isPurchased ? "Purchased" : "Not Purchased")"
            },
            onServerVerificationRequired: { result, consumableType in
                logger.debug("Server verification required: \(result.productId)")
                statusMessage = "Verifying purchase: \(result.productId)..."
                // Auto-complete for demo (no real server)
                Noctua.completePurchaseProcessing(
                    purchaseToken: result.purchaseToken,
                    consumableType: consumableType,
                    verified: true,
                    callback: { success in
                        statusMessage = "Verification completed: \(success ? "OK" : "Failed")"
                    }
                )
            },
            onStoreKitError: { error, message in
                logger.error("StoreKit error: \(error.rawValue) - \(message)")
                storeKitError = "Error(\(error.rawValue)): \(message)"
                statusMessage = "Error: \(message)"
            }
        )

        // Register default test products
        for (id, type) in defaultTestProducts {
            Noctua.registerProduct(productId: id, consumableType: type)
        }

        storeKitInitialized = true
        statusMessage = "StoreKit initialized"
    }
}

#Preview {
    ContentView(gameId: 1)
}
