import SwiftUI
import os
import NoctuaSDK

// MARK: - Account Model

struct AccountModel: Identifiable {
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

// MARK: - Account ViewModel

class AccountViewModel: ObservableObject {
    @Published var accounts: [AccountModel] = []
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "AccountViewModel")

    init() {
        loadAccounts()
    }

    func loadAccounts() {
        accounts = Noctua.getAllAccounts().map { account in
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
        Noctua.putAccount(gameId: gameId, playerId: (1000 * gameId) + randomPlayerId, rawData: UUID().uuidString)
        logger.debug("Random account saved")
        loadAccounts()
    }

    func deleteAccount(gameId: Int64, playerId: Int64) {
        Noctua.deleteAccount(gameId: gameId, playerId: playerId)
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

// MARK: - Account Section

struct AccountSection: View {
    @ObservedObject var viewModel: AccountViewModel
    let gameId: Int64

    private let maxDisplayedAccounts = 5

    var body: some View {
        VStack(spacing: 8) {
            // Action Buttons
            HStack(spacing: 8) {
                Button(action: {
                    viewModel.saveRandomAccount(gameId: gameId)
                }) {
                    actionButtonLabel("Add Account", color: .blue)
                }

                Button(action: {
                    viewModel.deleteRandomAccount(gameId: gameId)
                }) {
                    actionButtonLabel("Delete Random", color: .red)
                }
            }

            Button(action: {
                viewModel.loadAccounts()
            }) {
                actionButtonLabel("Refresh", color: .gray)
            }

            // Account Count
            if !viewModel.accounts.isEmpty {
                HStack {
                    Text("Accounts")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(viewModel.accounts.count)")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }
                .padding(.top, 4)
            }

            // Account Cards
            let displayedAccounts = Array(viewModel.accounts.prefix(maxDisplayedAccounts))

            ForEach(displayedAccounts) { account in
                AccountCard(account: account) {
                    viewModel.deleteAccount(gameId: account.gameId, playerId: account.playerId)
                }
            }

            // "+N more" indicator
            if viewModel.accounts.count > maxDisplayedAccounts {
                Text("+\(viewModel.accounts.count - maxDisplayedAccounts) more")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
            }

            // Empty State
            if viewModel.accounts.isEmpty {
                Text("No accounts found")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
    }
}

// MARK: - Account Card

struct AccountCard: View {
    let account: AccountModel
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    // Player ID
                    Text("Player: \(account.playerId)")
                        .font(.system(size: 13, weight: .semibold))

                    // Updated date
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Text(formatDate(account.lastUpdated))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    // Raw data (truncated)
                    if !account.rawData.isEmpty {
                        Text(String(account.rawData.prefix(30)) + (account.rawData.count > 30 ? "..." : ""))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    // Game ID chip
                    Text("G:\(account.gameId)")
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(6)

                    // Delete button
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .padding(6)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }

    private func formatDate(_ timestamp: Int64) -> String {
        guard timestamp > 0 else { return "N/A" }
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, HH:mm"
        return formatter.string(from: date)
    }
}
