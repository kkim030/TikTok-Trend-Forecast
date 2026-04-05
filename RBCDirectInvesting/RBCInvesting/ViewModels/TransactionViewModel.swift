import Foundation

@MainActor
class TransactionViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 0
    @Published var hasMore = true

    func loadTransactions(reset: Bool = false) async {
        if reset {
            currentPage = 0
            transactions = []
            hasMore = true
        }
        guard hasMore else { return }
        isLoading = true
        do {
            let page: PageResponse<Transaction> = try await APIService.shared.get("/transactions?page=\(currentPage)&size=20")
            if reset {
                transactions = page.content
            } else {
                transactions.append(contentsOf: page.content)
            }
            hasMore = currentPage < page.totalPages - 1
            currentPage += 1
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
