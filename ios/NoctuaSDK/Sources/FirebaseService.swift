//
//  FirebaseService.swift
//  NoctuaSDK
//
//  Created by Noctua Eng 2 on 05/08/24.
//

import Foundation
#if canImport(FirebaseAnalytics)
import FirebaseCore
import FirebaseAnalytics
import FirebaseInstallations
import FirebaseRemoteConfig
#endif
import os

enum FirebaseServiceError : Error {
    case firebaseNotFound
    case invalidConfig(String)
}

struct FirebaseServiceConfig : Codable {
    let ios: FirebaseServiceIosConfig?
}

struct FirebaseServiceIosConfig : Codable {
    let customEventDisabled: Bool?
}

class FirebaseService {
    let config: FirebaseServiceIosConfig
    private var remoteConfig: RemoteConfig?

    init(config: FirebaseServiceIosConfig) throws {
#if canImport(FirebaseAnalytics)
        logger.info("Firebase module detected")
        self.config = config

        if (FirebaseApp.app() == nil)
        {
            FirebaseApp.configure()
        }

        Analytics.setAnalyticsCollectionEnabled(true)

        // Initialize Remote Config
        remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600
        remoteConfig?.configSettings = settings
        fetchRemoteConfig()

#else
        throw FirebaseServiceError.firebaseNotFound
#endif
    }
    
    private func getAdplatform(from source: String) -> String {
        switch source {
        case "applovin_max_sdk":
            return "appLovin"
        case "admob_sdk":
            return "admob"
        case "unity_ads_sdk":
            return "unity"
        default:
            return "unknown"
        }
    }
    
    func trackAdRevenue(source: String, revenue: Double, currency: String, extraPayload: [String:Any]) {
#if canImport(FirebaseAnalytics)
        var parameters: [String:Any] = [
            AnalyticsParameterAdPlatform: getAdplatform(from: source),
            AnalyticsParameterAdSource: source,
            AnalyticsParameterValue: revenue,
            AnalyticsParameterCurrency: currency
        ]
        
        for (key, value) in extraPayload {
            parameters[key] = value
        }

        Analytics.logEvent(AnalyticsEventAdImpression, parameters: parameters)

        logger.debug("'ad_revenue' tracked: source: \(source), revenue: \(revenue), currency: \(currency), extraPayload: \(extraPayload)")
#endif
    }
    
    func trackPurchase(orderId: String, amount: Double, currency: String, extraPayload: [String:Any]) {
#if canImport(FirebaseAnalytics)
        var parameters: [String: Any] = [
            AnalyticsParameterTransactionID: orderId,
            AnalyticsParameterValue: amount,
            AnalyticsParameterCurrency: currency
        ]
        
        for (key, value) in extraPayload {
            parameters[key] = value
        }

        Analytics.logEvent(AnalyticsEventPurchase, parameters: parameters)

        logger.debug("'\(AnalyticsEventPurchase)' tracked: currency: \(currency), amount: \(amount), orderId: \(orderId), extraPayload: \(extraPayload)")
#endif
    }
    
    func trackCustomEvent(_ eventName: String, payload: [String:Any]) {
#if canImport(FirebaseAnalytics)
        if (config.customEventDisabled ?? false) {
            return
        }
        
        let suffix = (payload["suffix"] as? CustomStringConvertible).flatMap { "\($0)".isEmpty ? nil : "_\($0)" } ?? ""
        let payload = payload.filter { $0.key != "suffix" }
        
        Analytics.logEvent("gf_\(eventName)\(suffix)", parameters: payload)

        logger.debug("'gf_\(eventName)\(suffix)' (custom) tracked: payload: \(payload)")
#endif
    }

    func trackCustomEventWithRevenue(_ eventName: String, revenue: Double, currency: String, extraPayload: [String:Any]) {
#if canImport(FirebaseAnalytics)
        if (config.customEventDisabled ?? false) {
            return
        }
        
        var parameters: [String: Any] = [
            AnalyticsParameterValue: revenue,
            AnalyticsParameterCurrency: currency
        ]
        
        for (key, value) in extraPayload {
            parameters[key] = value
        }
        
        Analytics.logEvent("gf_\(eventName)", parameters: extraPayload)

        logger.debug("'gf_\(eventName)' (custom) tracked: payload: \(extraPayload)")
#endif
    }
    
    func getFirebaseInstallationID(completion: @escaping (String) -> Void) {
#if canImport(FirebaseInstallations)
        Installations.installations().installationID { id, error in
            if let error = error {
                self.logger.debug("Error fetching installation ID: \(error)")
                completion("")
                return
            }
            if let id = id {
                self.logger.debug("Firebase Installation ID: \(id)")
                completion(id)
            } else {
                completion("")
            }
        }
#endif
    }
    
    func getFirebaseSessionID(completion: @escaping (String) -> Void) {
#if canImport(FirebaseAnalytics)
        Analytics.sessionID { sessionID, error in
            if let error = error {
                self.logger.debug("Error fetching session ID: \(error)")
                completion("")
                return
            }
            self.logger.debug("Firebase Analytics Session ID: \(sessionID)")
            completion(String(sessionID))
        }
#endif
    }

    func fetchRemoteConfig() {
#if canImport(FirebaseRemoteConfig)
        remoteConfig?.fetchAndActivate { status, error in
            if let error = error {
                self.logger.error("Failed to fetch and activate Firebase RemoteConfig: \(error.localizedDescription)")
                return
            }

            switch status {
            case .successFetchedFromRemote:
                self.logger.debug("Firebase Remote Config params updated: fetched from remote")
            case .successUsingPreFetchedData:
                self.logger.debug("Firebase Remote Config params updated: using pre-fetched data")
            case .error:
                self.logger.error("Firebase Remote Config fetch error")
            @unknown default:
                self.logger.debug("Firebase Remote Config unknown status")
            }
        }
#endif
    }

    func getFirebaseRemoteConfigString(key: String) -> String {
#if canImport(FirebaseRemoteConfig)
        return remoteConfig?.configValue(forKey: key).stringValue ?? ""
#else
        return ""
#endif
    }

    func getFirebaseRemoteConfigBoolean(key: String) -> Bool {
#if canImport(FirebaseRemoteConfig)
        return remoteConfig?.configValue(forKey: key).boolValue ?? false
#else
        return false
#endif
    }

    func getFirebaseRemoteConfigDouble(key: String) -> Double {
#if canImport(FirebaseRemoteConfig)
        return remoteConfig?.configValue(forKey: key).numberValue.doubleValue ?? 0.0
#else
        return 0.0
#endif
    }

    func getFirebaseRemoteConfigLong(key: String) -> Int64 {
#if canImport(FirebaseRemoteConfig)
        return remoteConfig?.configValue(forKey: key).numberValue.int64Value ?? 0
#else
        return 0
#endif
    }

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: FirebaseService.self)
    )
}
