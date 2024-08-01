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
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "NoctuaSDKExampleApp")
    
    init() {
        try! Noctua.initialize()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
