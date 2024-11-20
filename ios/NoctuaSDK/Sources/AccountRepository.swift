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
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccessGroup as String: keychainAccessGroup,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: "\(account.gameId)_\(account.playerId)",
        ]
        
        let attributesToUpdate = [
            kSecValueData as String: "\(account.rawData)\n\(account.lastUpdated)".data(using: .utf8)!
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        if status == errSecItemNotFound {
            let addStatus = SecItemAdd(toCredentials(account) as CFDictionary, nil)
            if addStatus != errSecSuccess {
                logger.error("error adding account to keychain: \(addStatus)")
                
                return
            }
        } else if status != errSecSuccess {
            logger.error("error updating account in keychain: \(status)")
            
            return
        }
        
        logger.debug("added account '\(account.gameId)_\(account.playerId)' to keychain")
    }
    
    func getAll() -> [Account] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccessGroup as String: keychainAccessGroup,
            kSecAttrService as String: serviceName,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let items = result as? [[String: Any]] else {
            if status != errSecItemNotFound {
                logger.error("error retrieving all accounts: \(status)")
            }
            
            return []
        }
        
        logger.debug("retrieved \(items.count) accounts")
        
        return items.compactMap { fromCredentials($0) }
    }
    
    func getSingle(gameId: Int64, playerId: Int64) -> Account? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccessGroup as String: keychainAccessGroup,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: "\(gameId)_\(playerId)",
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let credentials = result as? [String: Any] else {
            if status != errSecItemNotFound {
                logger.error("error retrieving account: \(status)")
            }
            
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
            kSecAttrAccessGroup as String: keychainAccessGroup,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: "\(gameId)_\(playerId)"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess {
            logger.error("error deleting account: \(status)")
        }
    }
    
    private func toCredentials(_ account: Account) -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccessGroup as String: keychainAccessGroup,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: "\(account.gameId)_\(account.playerId)",
            kSecValueData as String: "\(account.rawData)\n\(account.lastUpdated)".data(using: .utf8)!
        ]
    }
    
    private func fromCredentials(_ credentials: [String: Any]) -> Account? {
        let compositeId: String = credentials[kSecAttrAccount as String] as? String ?? ""

        guard
            compositeId != "",
            let valueData = credentials[kSecValueData as String] as? Data,
            let stringValue = String(data: valueData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        else {
            logger.error("error parsing credentials \(compositeId)")
            
            return nil
        }
        
        guard let separatorIndex = stringValue.lastIndex(of: "\n")
        else {
            logger.error("error parsing account data from credentials")
            
            return nil
        }
        
        let rawData = stringValue[..<separatorIndex]
        let lastUpdatedStart = stringValue.index(after: separatorIndex)
        let lastUpdatedString = stringValue[lastUpdatedStart...]
        let lastUpdated = Int64(lastUpdatedString) ?? 0

        let idParts = compositeId.split(separator: "_")
        
        guard idParts.count == 2, let gameId = Int64(idParts[0]), let playerId = Int64(idParts[1]) else {
            logger.error("error parsing account ID from compositeId")
            
            return nil
        }
        
        return Account(playerId: playerId, gameId: gameId, rawData: String(rawData), lastUpdated: lastUpdated)
    }

    private let keychainAccessGroup = "\(Bundle.main.infoDictionary?["AppIdPrefix"] ?? "")com.noctuagames.accounts"
    private let serviceName = "com.noctuagames.accounts.AccountRepository"
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: AccountRepository.self)
    )
}
