import Security
import os

struct Account : Encodable {
    let playerId: Int64
    let gameId: Int64
    let rawData: String
    let lastUpdated: Int64
    
    init(playerId: Int64, gameId: Int64, rawData: String, lastUpdated: Int64 = Int64(Date().timeIntervalSince1970 * 1000)) {
        self.playerId = playerId
        self.gameId = gameId
        self.rawData = rawData
        self.lastUpdated = lastUpdated
    }
}

class AccountRepository {
    func put(_ account: Account) {
        let credentials = toCredentials(account)
        
        // Delete any existing item
        SecItemDelete(credentials as CFDictionary)
        
        // Add the new item
        let status = SecItemAdd(credentials as CFDictionary, nil)
        if status != errSecSuccess {
            logger.error("Error adding account to keychain: \(status)")
            
            return
        }
        
        logger.debug("Added account '\(account.gameId)_\(account.playerId)' to keychain")
    }
    
    func getAll() -> [Account] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecAttrAccessGroup as String: keychainAccessGroup
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let items = result as? [[String: Any]] else {
            logger.error("Error retrieving all accounts: \(status)")
            
            return []
        }
        
        logger.debug("Retrieved \(items.count) accounts")
        
        return items.compactMap { fromCredentials($0) }
    }
    
    func getSingle(gameId: Int64, playerId: Int64) -> Account? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "\(gameId)_\(playerId)",
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecAttrAccessGroup as String: keychainAccessGroup
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let credentials = result as? [String: Any] else {
            logger.error("Error retrieving account: \(status)")
            return nil
        }
        
        return fromCredentials(credentials)
    }
    
    func getByPlayerId(playerId: Int64) -> [Account] {
        return getAll().filter { $0.playerId == playerId }
    }
    
    func delete(gameId: Int64, playerId: Int64) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "\(gameId)_\(playerId)",
            kSecAttrAccessGroup as String: keychainAccessGroup
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess {
            logger.error("Error deleting account: \(status)")
        }
    }
    
    private func toCredentials(_ account: Account) -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "\(account.gameId)_\(account.playerId)",
            kSecValueData as String: "\(account.rawData)\n\(account.lastUpdated)".data(using: .utf8)!,
            kSecAttrAccessGroup as String: keychainAccessGroup
        ]
    }
    
    private func fromCredentials(_ credentials: [String: Any]) -> Account? {
        guard
            let valueData = credentials[kSecValueData as String] as? Data,
            let stringValue = String(data: valueData, encoding: .utf8),
            let compositeId = credentials[kSecAttrAccount as String] as? String
        else {
            logger.error("Error parsing credentials")
            
            return nil
        }
        
        let parts = stringValue.split(separator: "\n")

        guard
            parts.count >= 2,
            let rawData = parts.first,
            let lastUpdatedString = parts.last,
            let lastUpdated = Int64(lastUpdatedString)
        else {
            logger.error("Error parsing account data from credentials")
            
            return nil
        }
        
        let idParts = compositeId.split(separator: "_")
        
        guard idParts.count == 2, let gameId = Int64(idParts[0]), let playerId = Int64(idParts[1]) else {
            logger.error("Error parsing account ID from compositeId")
            
            return nil
        }
        
        return Account(playerId: playerId, gameId: gameId, rawData: String(rawData), lastUpdated: lastUpdated)
    }

    private let keychainAccessGroup = "\(Bundle.main.infoDictionary?["AppIdPrefix"] ?? "")com.noctuagames.accounts"
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: AccountRepository.self)
    )
}
