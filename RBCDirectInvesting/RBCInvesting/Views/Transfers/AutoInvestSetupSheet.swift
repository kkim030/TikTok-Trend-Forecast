import SwiftUI

struct AutoInvestSetupSheet: View {
    @ObservedObject var autoInvestVM: AutoInvestViewModel
    @Environment(\.dismiss) var dismiss

    var editingRule: AutoInvestRule? = nil

    @State private var fromAccountId: UUID?
    @State private var toAccountId: UUID?
    @State private var symbol = ""
    @State private var amount = ""
    @State private var frequency: AutoInvestFrequency = .monthly

    var isEditing: Bool { editingRule != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("From Account") {
                    Picker("From", selection: $fromAccountId) {
                        Text("Select account").tag(nil as UUID?)
                        ForEach(autoInvestVM.accounts) { acc in
                            Text("\(acc.accountType.displayName) — \(acc.accountNumber)")
                                .tag(acc.id as UUID?)
                        }
                    }
                }

                Section("To Account") {
                    Picker("To", selection: $toAccountId) {
                        Text("Select account").tag(nil as UUID?)
                        ForEach(autoInvestVM.accounts) { acc in
                            Text("\(acc.accountType.displayName) — \(acc.accountNumber)")
                                .tag(acc.id as UUID?)
                        }
                    }
                }

                Section("Investment") {
                    TextField("Symbol (e.g. XEQT)", text: $symbol)
                        .autocapitalization(.allCharacters)
                }

                Section("Amount") {
                    HStack {
                        Text("$")
                        TextField("500.00", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Frequency") {
                    Picker("Timing", selection: $frequency) {
                        ForEach(AutoInvestFrequency.allCases, id: \.self) {
                            Text($0.displayName)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.rbcBlue)
                        Text("Orders will be executed as market orders during regular trading hours (9:30 AM – 4:00 PM ET). You can pause, modify, or cancel anytime.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let error = autoInvestVM.errorMessage {
                    Section {
                        Text(error).foregroundColor(.red)
                    }
                }

                Section {
                    Button(isEditing ? "Update Rule" : "Save Auto-Invest Rule") {
                        saveRule()
                    }
                    .buttonStyle(RBCButtonStyle())
                    .disabled(fromAccountId == nil || toAccountId == nil || symbol.isEmpty || amount.isEmpty)
                }
            }
            .navigationTitle(isEditing ? "Edit Auto-Invest" : "Set Up Auto-Investing")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let rule = editingRule {
                    fromAccountId = rule.fromAccountId
                    toAccountId = rule.toAccountId
                    symbol = rule.symbol
                    amount = String(format: "%.2f", rule.amount)
                    frequency = rule.frequency
                }
            }
        }
    }

    private func saveRule() {
        guard let from = fromAccountId, let to = toAccountId,
              let amt = Double(amount) else { return }

        if let existing = editingRule {
            var updated = existing
            updated.fromAccountId = from
            updated.toAccountId = to
            updated.symbol = symbol.uppercased()
            updated.amount = amt
            updated.frequency = frequency
            autoInvestVM.updateRule(updated)
        } else {
            let rule = AutoInvestRule(
                id: UUID(),
                fromAccountId: from,
                toAccountId: to,
                amount: amt,
                frequency: frequency,
                symbol: symbol.uppercased(),
                isActive: true,
                createdAt: Date()
            )
            autoInvestVM.addRule(rule)
        }
        dismiss()
    }
}
