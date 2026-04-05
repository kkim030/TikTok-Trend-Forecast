import Foundation

@MainActor
class AutoInvestViewModel: ObservableObject {
    @Published var rules: [AutoInvestRule] = []
    @Published var accounts: [AccountSummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let storageKey = "autoInvestRules"

    func loadRules() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([AutoInvestRule].self, from: data) {
            rules = decoded
        }
    }

    func loadAccounts() async {
        do {
            accounts = try await APIService.shared.get("/accounts")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addRule(_ rule: AutoInvestRule) {
        rules.append(rule)
        saveRules()
        successMessage = "Auto-invest rule created for \(rule.symbol)"
    }

    func deleteRule(id: UUID) {
        rules.removeAll { $0.id == id }
        saveRules()
    }

    func toggleRule(id: UUID) {
        if let index = rules.firstIndex(where: { $0.id == id }) {
            rules[index].isActive.toggle()
            saveRules()
        }
    }

    func updateRule(_ rule: AutoInvestRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
            saveRules()
        }
    }

    private func saveRules() {
        if let data = try? JSONEncoder().encode(rules) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
