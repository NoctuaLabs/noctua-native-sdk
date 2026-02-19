import Foundation

class AccountPresenter {
    private let accountRepo: AccountRepositoryProtocol
    private let logger: NoctuaLogger

    init(accountRepo: AccountRepositoryProtocol, logger: NoctuaLogger) {
        self.accountRepo = accountRepo
        self.logger = logger
    }

    func putAccount(gameId: Int64, playerId: Int64, rawData: String) {
        let account = Account(playerId: playerId, gameId: gameId, rawData: rawData)
        accountRepo.put(account)
    }

    func getAllAccounts() -> [[String: Any]] {
        let accounts = accountRepo.getAll()

        return accounts.map {
            account in
            [
                "playerId": account.playerId,
                "gameId": account.gameId,
                "rawData": account.rawData,
                "lastUpdated": account.lastUpdated
            ]
        }
    }

    func getSingleAccount(gameId: Int64, playerId: Int64) -> [String: Any]? {
        let account = accountRepo.getSingle(gameId: gameId, playerId: playerId)

        if account == nil {
            return nil
        }

        return [
            "playerId": account!.playerId,
            "gameId": account!.gameId,
            "rawData": account!.rawData,
            "lastUpdated": account!.lastUpdated
        ]
    }

    func deleteAccount(gameId: Int64, playerId: Int64) {
        accountRepo.delete(gameId: gameId, playerId: playerId)
    }
}
