//
//  ContentView.swift
//  NoctuaSDKExample
//
//  Created by SDK Dev on 01/08/24.
//

import SwiftUI
import os
import NoctuaSDK
import AppTrackingTransparency
import AdSupport

struct AccountModel : Identifiable {
    let id: Int64
    let playerId: Int64
    let gameId: Int64
    let rawData: String
    let lastUpdated: Int64
    
    init(playerId: Int64, gameId: Int64, rawData: String, lastUpdated: Int64 = 0) {
        self.id = playerId
        self.playerId = playerId
        self.gameId = gameId
        self.rawData = rawData
        self.lastUpdated = lastUpdated
    }
}

class AccountViewModel: ObservableObject {
    @Published var accounts: [AccountModel] = []
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "AccountViewModel")
    
    init() {
        loadAccounts()
    }
    
    func loadAccounts() {
        accounts = Noctua.getAllAccounts().map {
            account in
            AccountModel(
                playerId: account["playerId"] as? Int64 ?? 0,
                gameId: account["gameId"] as? Int64 ?? 0,
                rawData: account["rawData"] as? String ?? "",
                lastUpdated: account["lastUpdated"] as? Int64 ?? 0
            )
        }
    }
    
    func saveRandomAccount(gameId: Int64) {
        let randomPlayerId = Int64.random(in: 1...3)
        Noctua.putAccount(gameId: gameId, playerId: (1000*gameId) + randomPlayerId, rawData: UUID().uuidString)
        logger.debug("Random account saved")
        loadAccounts()
    }
    
    func deleteRandomAccount(gameId: Int64) {
        let offset = gameId * 1000
        let filteredAccounts = accounts.filter { $0.playerId >= offset && $0.playerId < offset + 1000 }
        if let accountToDelete = filteredAccounts.randomElement() {
            Noctua.deleteAccount(gameId: accountToDelete.gameId, playerId: accountToDelete.playerId)
            loadAccounts()
        } else {
            logger.debug("No accounts to delete")
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = AccountViewModel()
    let gameId: Int64
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ContentView")
    
    func requestPermission() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    // Tracking authorization dialog was shown
                    // and we are authorized
                    print("Authorized")
                    
                    // Now that we are authorized we can get the IDFA
                    print(ASIdentifierManager.shared().advertisingIdentifier)
                case .denied:
                    // Tracking authorization dialog was
                    // shown and permission is denied
                    print("Denied")
                case .notDetermined:
                    // Tracking authorization dialog has not been shown
                    print("Not Determined")
                case .restricted:
                    print("Restricted")
                @unknown default:
                    print("Unknown")
                }
            }
        }
    }

    
    var body: some View {
        VStack {
            
            Button(action: {
                requestPermission()
                
                let attribution = Noctua.getAdjustCurrentAttribution()
                logger.debug("""
                Current Adjust Attribution:
                - trackerToken: \(attribution["trackerToken"] as? String ?? "nil")
                - trackerName: \(attribution["trackerName"] as? String ?? "nil")
                - network: \(attribution["network"] as? String ?? "nil")
                - campaign: \(attribution["campaign"] as? String ?? "nil")
                - adgroup: \(attribution["adgroup"] as? String ?? "nil")
                - creative: \(attribution["creative"] as? String ?? "nil")
                - clickLabel: \(attribution["clickLabel"] as? String ?? "nil")
                - adid: \(attribution["adid"] as? String ?? "nil")
                - costType: \(attribution["costType"] as? String ?? "nil")
                - costAmount: \(attribution["costAmount"] as? Double ?? 0)
                - costCurrency: \(attribution["costCurrency"] as? String ?? "nil")
                """)
            }) {
                Text("Get Adjust Attribution")
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button(action: {
                Noctua.trackAdRevenue(source: "admob_sdk", revenue: 1.3, currency: "USD", extraPayload: [:])
                logger.debug("Track Ad Revenue tapped")
            }) {
                Text("Track Ad Revenue")
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button(action: {
                Noctua.trackPurchase(orderId: "orderId", amount: 1.7, currency: "USD", extraPayload: [:])
                logger.debug("Track Purchase tapped")
            }) {
                Text("Track Purchase")
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button(action: {
                Noctua.trackCustomEvent("login", payload: ["k1": "v1", "k2" : "v2", "suffix": 123])
                Noctua.trackCustomEventWithRevenue("login", revenue: 0.9, currency: "USD")
                logger.debug("Track Custom Event tapped")
            }) {
                Text("Track Custom Event")
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button(action: {
                Task {
                    
                    let productId = "noctua.unitysdktest.noads.banner"
                    var isPurchased = false
                    
                    await Noctua.getProductPurchasedById(id: productId, completion: { purchased in
                        logger.debug("Product is \(purchased)")
                        isPurchased = purchased
                    })
                    
                    if isPurchased {
                        logger.debug("Product \(productId) already purchased!")
                        return
                    }
                    
                    Noctua.purchaseItem(productId, completion: { (success, message) in
                        logger.debug("Purchase Item tapped: \(success), \(message)")
                    });
                    
                }
            }) {
                Text("Purchase Item")
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Button(action: {
                Noctua.getActiveCurrency("noctua.sdktest.ios.pack1", completion: { (success, message) in
                    logger.debug("Get Active Currency tapped: \(success), \(message)")
                });
            }) {
                Text("Get Active Currency")
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button(action: {
                fatalError("Crash was triggered")
            }) {
                Text("Crash Me")
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button(action: {
                viewModel.saveRandomAccount(gameId: gameId)
//                Noctua.saveEvents(jsonString: "{\"event\":\"test_event\",\"value\":123}")
//
//                Noctua.getEvents(onResult: { events in
//                    logger.debug("[NoctuaInternal] Events retrieved: \(events) event counts: \(events.count)")
//                })
            }) {
                Text("Save Random Account")
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button(action: {
                 viewModel.deleteRandomAccount(gameId: gameId)
//                Noctua.deleteEvents()
            }) {
                Text("Delete Random Account")
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Button(action: {
                let welcomeMessage = Noctua.getFirebaseRemoteConfigString(key: "welcome_message")
                logger.debug("Firebase Remote Config value: \(welcomeMessage ?? "")")
            }) {
                Text("Get Firebase Remote Config")
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            List(viewModel.accounts) { account in
                Text("\(account.lastUpdated)-\(account.playerId)-\(account.rawData)")
                    .font(.system(size: 10))
            }
        }
        .padding()
    }
}

#Preview {
    ContentView(gameId: 1)
}
