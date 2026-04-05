import Foundation

@MainActor
class PortfolioViewModel: ObservableObject {
    @Published var portfolio: PortfolioOverview?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadPortfolio() async {
        isLoading = true
        do {
            portfolio = try await APIService.shared.get("/accounts/portfolio")
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
