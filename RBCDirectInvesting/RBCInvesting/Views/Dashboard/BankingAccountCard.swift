import SwiftUI

struct BankingAccountCard: View {
    let account: BankingAccount

    var body: some View {
        HStack(spacing: 0) {
            // Blue accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.rbcBlue)
                .frame(width: 4)
                .padding(.vertical, 8)

            HStack(spacing: 12) {
                Image(systemName: account.type.icon)
                    .font(.title3)
                    .foregroundColor(.rbcBlue)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(account.type.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(account.accountNumber)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(account.balance.currencyFormatted)
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                    if account.type == .creditLine, let limit = account.creditLimit {
                        Text("Limit: \(limit.currencyFormatted)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}
