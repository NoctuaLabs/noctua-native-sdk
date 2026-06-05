import SwiftUI
import os
import NoctuaSDK
import AppTrackingTransparency
import AdSupport

struct TrackingSection: View {
    let logger: Logger

    var body: some View {
        VStack(spacing: 8) {
            Button(action: {
                requestPermission()

                Noctua.getAdjustCurrentAttribution { attribution in
                    logger.debug("""
                    Current Adjust Attribution:
                    - trackerToken: \(attribution["trackerToken"] as? String ?? "nil")
                    - trackerName: \(attribution["trackerName"] as? String ?? "nil")
                    - network: \(attribution["network"] as? String ?? "nil")
                    - campaign: \(attribution["campaign"] as? String ?? "nil")
                    - adgroup: \(attribution["adgroup"] as? String ?? "nil")
                    - creative: \(attribution["creative"] as? String ?? "nil")
                    - clickLabel: \(attribution["clickLabel"] as? String ?? "nil")
                    - costType: \(attribution["costType"] as? String ?? "nil")
                    - costAmount: \(attribution["costAmount"] as? Double ?? 0)
                    - costCurrency: \(attribution["costCurrency"] as? String ?? "nil")
                    """)
                }
            }) {
                actionButtonLabel("Get Adjust Attribution")
            }

            Button(action: {
                Noctua.trackAdRevenue(source: "admob_sdk", revenue: 1.3, currency: "USD", extraPayload: [:])
                logger.debug("Track Ad Revenue tapped")
            }) {
                actionButtonLabel("Track Ad Revenue")
            }

            Button(action: {
                Noctua.trackPurchase(orderId: "orderId", amount: 1.7, currency: "USD", extraPayload: [:])
                logger.debug("Track Purchase tapped")
            }) {
                actionButtonLabel("Track Purchase")
            }

            Button(action: {
                Noctua.trackCustomEvent("login", payload: ["k1": "v1", "k2" : "v2", "suffix": 123])
                Noctua.trackCustomEventWithRevenue("login", revenue: 0.9, currency: "USD")
                logger.debug("Track Custom Event tapped")
            }) {
                actionButtonLabel("Track Custom Event")
            }

            Button(action: {
                Noctua.getAdjustAdid { adid in
                    logger.debug("Adjust ADID: \(adid ?? "nil")")
                }
            }) {
                actionButtonLabel("Get Adjust ADID")
            }

            Button(action: {
                Noctua.getAdjustIdfa { idfa in
                    logger.debug("Adjust IDFA: \(idfa ?? "nil")")
                }
            }) {
                actionButtonLabel("Get Adjust IDFA")
            }

            Button(action: {
                Noctua.getAdjustIdfv { idfv in
                    logger.debug("Adjust IDFV: \(idfv ?? "nil")")
                }
            }) {
                actionButtonLabel("Get Adjust IDFV")
            }

            Button(action: {
                Noctua.getAdjustSdkVersion { version in
                    logger.debug("Adjust SDK Version: \(version ?? "nil")")
                }
            }) {
                actionButtonLabel("Get Adjust SDK Version")
            }
        }
    }

    private func requestPermission() {
        ATTrackingManager.requestTrackingAuthorization { status in
            switch status {
            case .authorized:
                print("Authorized")
                print(ASIdentifierManager.shared().advertisingIdentifier)
            case .denied:
                print("Denied")
            case .notDetermined:
                print("Not Determined")
            case .restricted:
                print("Restricted")
            @unknown default:
                print("Unknown")
            }
        }
    }
}
