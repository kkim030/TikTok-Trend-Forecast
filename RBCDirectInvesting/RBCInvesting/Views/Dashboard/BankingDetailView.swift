import SwiftUI

struct BankingDetailView: View {
    let account: BankingAccount

    var body: some View {
        List {
            Section {
                HStack(spacing: 14) {
                    Image(systemName: account.type.icon)
                        .font(.system(size: 36))
                        .foregroundColor(.rbcBlue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(account.name)
                            .font(.headline)
                        Text(account.accountNumber)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Balance") {
                HStack {
                    Text("Current Balance")
                    Spacer()
                    Text(account.balance.currencyFormatted)
                        .fontWeight(.bold)
                        .foregroundColor(account.balance >= 0 ? .primary : .lossRed)
                }

                if account.type == .creditLine, let limit = account.creditLimit {
                    HStack {
                        Text("Credit Limit")
                        Spacer()
                        Text(limit.currencyFormatted)
                    }

                    HStack {
                        Text("Available Credit")
                        Spacer()
                        Text((limit + account.balance).currencyFormatted)
                            .foregroundColor(.gainGreen)
                    }

                    HStack {
                        Text("Utilization")
                        Spacer()
                        let utilization = abs(account.balance) / limit * 100
                        Text(String(format: "%.1f%%", utilization))
                            .foregroundColor(utilization > 50 ? .lossRed : .gainGreen)
                    }
                }
            }

            Section {
                Button {} label: {
                    HStack {
                        Image(systemName: "arrow.left.arrow.right")
                        Text("Transfer Funds")
                    }
                    .foregroundColor(.rbcBlue)
                }
            }
        }
        .navigationTitle(account.type.displayName)
    }
}
