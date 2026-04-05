import Foundation

@MainActor
class WatchlistViewModel: ObservableObject {
    @Published var watchlists: [WatchlistResponse] = []
    @Published var quotes: [String: Quote] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadWatchlists() async {
        isLoading = true
        do {
            watchlists = try await APIService.shared.get("/watchlists")
            await loadQuotes()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadQuotes() async {
        let symbols = Set(watchlists.flatMap { $0.items?.map(\.symbol) ?? [] })
        for symbol in symbols {
            do {
                let q: Quote = try await APIService.shared.get("/quotes/\(symbol)")
                quotes[symbol] = q
            } catch {}
        }
    }

    func createWatchlist(name: String) async {
        do {
            let _: WatchlistResponse = try await APIService.shared.post("/watchlists",
                body: ["name": name])
            await loadWatchlists()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addItem(watchlistId: UUID, symbol: String, exchange: String = "TSX") async {
        do {
            let body = ["symbol": symbol, "exchange": exchange]
            let _: WatchlistItemResponse = try await APIService.shared.post("/watchlists/\(watchlistId)/items", body: body)
            await loadWatchlists()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeItem(watchlistId: UUID, itemId: UUID) async {
        do {
            try await APIService.shared.delete("/watchlists/\(watchlistId)/items/\(itemId)")
            await loadWatchlists()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteWatchlist(_ id: UUID) async {
        do {
            try await APIService.shared.delete("/watchlists/\(id)")
            await loadWatchlists()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
