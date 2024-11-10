//
//  NoctuaSDKExampleApp.swift
//  NoctuaSDKExample
//
//  Created by SDK Dev on 01/08/24.
//

import SwiftUI
import NoctuaSDK
import os

@main
struct NoctuaSDKExampleApp: App {
    let gameId: Int64
    
    init() {
        try! Noctua.initNoctua()
        
        gameId = if (Bundle.main.bundleIdentifier?.contains("unity") ?? false) { 1 } else { 2 }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(gameId: gameId)
        }
    }
}
