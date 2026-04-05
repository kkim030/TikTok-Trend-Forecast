import SwiftUI

struct AutoInvestRuleRow: View {
    let rule: AutoInvestRule
    let accounts: [AccountSummary]
    var onToggle: () -> Void

    private func accountName(for id: UUID) -> String {
        accounts.first(where: { $0.id == id })?.accountType.displayName ?? "Account"
    }

    var body: some View {
        HStack(spacing: 14) {
            RBCOutlinedCircleIcon(systemName: "repeat")

            VStack(alignment: .leading, spacing: 4) {
                Text(rule.symbol)
                    .font(.headline)

                Text("\(rule.amount.currencyFormatted) \(rule.frequency.displayName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("\(accountName(for: rule.fromAccountId)) → \(accountName(for: rule.toAccountId))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Next: \(rule.nextExecutionDescription)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { rule.isActive },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .tint(.rbcBlue)
        }
        .padding(.vertical, 4)
    }
}
