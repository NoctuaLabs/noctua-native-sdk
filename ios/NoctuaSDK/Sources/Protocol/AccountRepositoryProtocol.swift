import Foundation

protocol AccountRepositoryProtocol {
    func put(_ account: Account)
    func getAll() -> [Account]
    func getSingle(gameId: Int64, playerId: Int64) -> Account?
    func getByPlayerId(playerId: Int64) -> [Account]
    func delete(gameId: Int64, playerId: Int64)
}
