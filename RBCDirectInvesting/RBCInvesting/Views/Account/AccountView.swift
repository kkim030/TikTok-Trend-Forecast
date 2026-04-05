import SwiftUI

struct AccountView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var portfolioVM = PortfolioViewModel()
    @StateObject private var txVM = TransactionViewModel()

    var body: some View {
        List {
            // User info
            Section {
                HStack(spacing: 14) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.rbcBlue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(authVM.currentUser?.fullName ?? "User")
                            .font(.headline)
                        Text(authVM.currentUser?.email ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            // Account balances
            if let accounts = portfolioVM.portfolio?.accounts {
                Section("Account Balances") {
                    ForEach(accounts) { acc in
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: acc.accountType.icon)
                                    .foregroundColor(.rbcBlue)
                                Text(acc.accountType.displayName)
                                    .font(.subheadline.bold())
                                Text(acc.accountNumber)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }

                            HStack {
                                InfoCell(label: "Total", value: acc.totalValue.currencyFormatted)
                                InfoCell(label: "Cash", value: acc.cashBalance.currencyFormatted)
                                InfoCell(label: "Holdings", value: acc.holdingsValue.currencyFormatted)
                                InfoCell(label: "G/L", value: acc.totalGainLoss.changeFormatted,
                                         color: acc.totalGainLoss >= 0 ? .gainGreen : .lossRed)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            // Recent transactions
            Section("Recent Transactions") {
                if txVM.transactions.isEmpty {
                    Text("No transactions yet").foregroundColor(.secondary)
                } else {
                    ForEach(txVM.transactions.prefix(10)) { tx in
                        TransactionRow(transaction: tx)
                    }
                    NavigationLink("View All Transactions") {
                        TransactionsView()
                    }
                }
            }
        }
        .navigationTitle("Account")
        .refreshable {
            await portfolioVM.loadPortfolio()
            await txVM.loadTransactions(reset: true)
        }
        .task {
            await portfolioVM.loadPortfolio()
            await txVM.loadTransactions(reset: true)
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.type.icon)
                .foregroundColor(transaction.amount >= 0 ? .gainGreen : .lossRed)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description ?? transaction.type.rawValue)
                    .font(.subheadline)
                    .lineLimit(1)
                if let date = transaction.settledAt {
                    Text(formatDate(date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(transaction.amount.currencyFormatted)
                .font(.subheadline.bold())
                .foregroundColor(transaction.amount >= 0 ? .gainGreen : .lossRed)
        }
    }

    func formatDate(_ dateStr: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateStr) {
            let df = DateFormatter()
            df.dateStyle = .medium
            return df.string(from: date)
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateStr) {
            let df = DateFormatter()
            df.dateStyle = .medium
            return df.string(from: date)
        }
        return String(dateStr.prefix(10))
    }
}
