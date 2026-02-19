import SwiftUI
import os
import NoctuaSDK

struct StoreKitSection: View {
    @Binding var products: [NoctuaProductDetails]
    @Binding var purchases: [NoctuaPurchaseResult]
    @Binding var storeKitError: String?
    @Binding var productPurchaseStatus: NoctuaProductPurchaseStatus?
    @Binding var statusMessage: String
    let defaultProducts: [(String, ConsumableType)]
    let logger: Logger

    @State private var statusProductId: String = ""

    var body: some View {
        VStack(spacing: 8) {
            // Query & Action Buttons
            HStack(spacing: 8) {
                Button(action: {
                    let inappIds = defaultProducts
                        .filter { $0.1 != .subscription }
                        .map { $0.0 }
                    Noctua.queryProductDetails(productIds: inappIds, productType: .inapp)
                }) {
                    actionButtonLabel("Query INAPP", color: .blue)
                }

                Button(action: {
                    let subsIds = defaultProducts
                        .filter { $0.1 == .subscription }
                        .map { $0.0 }
                    Noctua.queryProductDetails(productIds: subsIds, productType: .subs)
                }) {
                    actionButtonLabel("Query SUBS", color: .purple)
                }
            }

            HStack(spacing: 8) {
                Button(action: {
                    Noctua.queryPurchases(productType: .inapp)
                }) {
                    actionButtonLabel("Get INAPP", color: .green)
                }

                Button(action: {
                    Noctua.queryPurchases(productType: .subs)
                }) {
                    actionButtonLabel("Get SUBS", color: .green)
                }
            }

            Button(action: {
                Noctua.restorePurchases()
            }) {
                actionButtonLabel("Restore Purchases", color: .orange)
            }

            Button(action: {
                logger.debug("StoreKit ready: \(Noctua.isStoreKitReady())")
                statusMessage = "StoreKit ready: \(Noctua.isStoreKitReady())"
            }) {
                actionButtonLabel("Check StoreKit Ready", color: .gray)
            }

            // Products List
            if !products.isEmpty {
                sectionLabel("Products (\(products.count))")

                ForEach(products, id: \.productId) { product in
                    ProductCard(product: product) {
                        Noctua.purchase(productId: product.productId)
                    }
                }
            }

            // Purchases List
            if !purchases.isEmpty {
                sectionLabel("Purchases (\(purchases.count))")

                ForEach(purchases, id: \.purchaseToken) { purchase in
                    PurchaseCard(purchase: purchase) {
                        let consumableType = defaultProducts
                            .first(where: { $0.0 == purchase.productId })?.1 ?? .nonConsumable
                        Noctua.completePurchaseProcessing(
                            purchaseToken: purchase.purchaseToken,
                            consumableType: consumableType,
                            verified: true,
                            callback: { success in
                                statusMessage = "Complete processing: \(success ? "OK" : "Failed")"
                            }
                        )
                    }
                }
            }

            // Product Purchase Status
            sectionLabel("Check Purchase Status")

            HStack(spacing: 8) {
                TextField("Product ID", text: $statusProductId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 12))

                Button(action: {
                    guard !statusProductId.isEmpty else { return }
                    Noctua.getProductPurchaseStatus(productId: statusProductId)
                }) {
                    Text("Check")
                        .font(.system(size: 12))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
            }

            if let status = productPurchaseStatus {
                PurchaseStatusCard(status: status)
            }

            // Error Display
            if let error = storeKitError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                }
                .padding(8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }
}

// MARK: - Product Card

struct ProductCard: View {
    let product: NoctuaProductDetails
    let onPurchase: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.title)
                        .font(.system(size: 13, weight: .semibold))
                    Text(product.productId)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(product.productDescription)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.formattedPrice)
                        .font(.system(size: 14, weight: .bold))

                    Text(product.productType == .subs ? "SUBS" : "INAPP")
                        .font(.system(size: 9, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(product.productType == .subs ? Color.purple.opacity(0.2) : Color.blue.opacity(0.2))
                        .cornerRadius(4)

                    Button(action: onPurchase) {
                        Text("Purchase")
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Purchase Card

struct PurchaseCard: View {
    let purchase: NoctuaPurchaseResult
    let onComplete: () -> Void

    private var stateText: String {
        switch purchase.purchaseState {
        case .purchased: return "PURCHASED"
        case .pending: return "PENDING"
        case .unspecified: return "UNSPECIFIED"
        @unknown default: return "UNKNOWN"
        }
    }

    private var stateColor: Color {
        switch purchase.purchaseState {
        case .purchased: return .green
        case .pending: return .orange
        default: return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(purchase.productId)
                        .font(.system(size: 12, weight: .semibold))

                    HStack(spacing: 4) {
                        Text(stateText)
                            .font(.system(size: 9, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(stateColor.opacity(0.2))
                            .foregroundColor(stateColor)
                            .cornerRadius(4)

                        if purchase.isAutoRenewing {
                            Text("AUTO-RENEW")
                                .font(.system(size: 9, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.purple.opacity(0.2))
                                .foregroundColor(.purple)
                                .cornerRadius(4)
                        }

                        Text("Qty: \(purchase.quantity)")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }

                    Text("Token: \(String(purchase.purchaseToken.prefix(20)))...")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: onComplete) {
                    Text("Complete")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Purchase Status Card

struct PurchaseStatusCard: View {
    let status: NoctuaProductPurchaseStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Status: \(status.productId)")
                .font(.system(size: 12, weight: .semibold))

            HStack(spacing: 8) {
                statusChip("Purchased", value: status.isPurchased)
                statusChip("Acknowledged", value: status.isAcknowledged)
                statusChip("Auto-Renewing", value: status.isAutoRenewing)
            }

            if !status.purchaseToken.isEmpty {
                Text("Token: \(String(status.purchaseToken.prefix(20)))...")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }

            if let orderId = status.orderId {
                Text("Order: \(orderId)")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }

    private func statusChip(_ label: String, value: Bool) -> some View {
        HStack(spacing: 2) {
            Image(systemName: value ? "checkmark.circle.fill" : "xmark.circle")
                .font(.system(size: 8))
                .foregroundColor(value ? .green : .red)
            Text(label)
                .font(.system(size: 9))
        }
    }
}
