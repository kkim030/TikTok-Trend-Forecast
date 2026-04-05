import Foundation

@MainActor
class OrderViewModel: ObservableObject {
    @Published var orders: [OrderResponse] = []
    @Published var accounts: [AccountSummary] = []
    @Published var quote: Quote?
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    func loadOrders() async {
        isLoading = true
        do {
            let page: PageResponse<OrderResponse> = try await APIService.shared.get("/orders?page=0&size=50")
            orders = page.content
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadAccounts() async {
        do {
            accounts = try await APIService.shared.get("/accounts")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchQuote(symbol: String) async {
        do {
            quote = try await APIService.shared.get("/quotes/\(symbol.uppercased())")
        } catch {
            quote = nil
        }
    }

    func submitOrder(_ request: OrderRequest) async {
        isSubmitting = true
        errorMessage = nil
        successMessage = nil
        do {
            let _: OrderResponse = try await APIService.shared.post("/orders", body: request)
            successMessage = "Order submitted successfully"
            await loadOrders()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }

    func cancelOrder(_ id: UUID) async {
        do {
            let _: OrderResponse = try await APIService.shared.post("/orders/\(id)/cancel")
            await loadOrders()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
