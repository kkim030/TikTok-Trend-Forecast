import Foundation

@MainActor
class BankingViewModel: ObservableObject {
    @Published var accounts: [BankingAccount] = []
    @Published var isLoading = false
    @Published var totalBankingBalance: Double = 0

    func loadAccounts() {
        isLoading = true
        accounts = [
            BankingAccount(
                id: UUID(),
                name: "RBC Day to Day Banking",
                type: .chequing,
                accountNumber: "4519-872",
                balance: 4_823.45,
                institution: "Royal Bank"
            ),
            BankingAccount(
                id: UUID(),
                name: "RBC High Interest eSavings",
                type: .savings,
                accountNumber: "4519-901",
                balance: 12_500.00,
                institution: "Royal Bank"
            ),
            BankingAccount(
                id: UUID(),
                name: "RBC Royal Credit Line",
                type: .creditLine,
                accountNumber: "5678-123",
                balance: -2_150.00,
                creditLimit: 15_000.00,
                institution: "Royal Bank"
            ),
        ]
        totalBankingBalance = accounts.reduce(0) { $0 + $1.balance }
        isLoading = false
    }
}
