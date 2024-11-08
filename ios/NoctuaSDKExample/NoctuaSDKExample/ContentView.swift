//
//  ContentView.swift
//  NoctuaSDKExample
//
//  Created by SDK Dev on 01/08/24.
//

import SwiftUI
import os
import NoctuaSDK

struct ContentView: View {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ContentView")
    
    var body: some View {
        VStack {
            Button(action: {
                Noctua.trackAdRevenue(source: "admob_sdk", revenue: 1.3, currency: "USD", extraPayload: [:])
                logger.debug("Track Ad Revenue tapped")
            }) {
                Text("Track Ad Revenue")
                    .frame(maxWidth: .infinity)
                    .padding()
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
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button(action: {
                Noctua.trackCustomEvent("TestSendEvent", payload: ["k1": "v1", "k2" : "v2", "suffix": 123])
                logger.debug("Track Custom Event tapped")
            }) {
                Text("Track Custom Event")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button(action: {
                Noctua.purchaseItem("noctua.sdktest.ios.pack1", completion: { (success, message) in
                    logger.debug("Purchase Item tapped: \(success), \(message)")
                });
            }) {
                Text("Purchase Item")
                    .frame(maxWidth: .infinity)
                    .padding()
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
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button(action: {
                fatalError("Crash was triggered")
            }) {
                Text("Crash Me")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

        }
        .padding()
    }
}

#Preview {
    ContentView()
}
