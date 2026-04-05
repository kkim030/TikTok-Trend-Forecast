import SwiftUI

struct RecentSearchItem: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let flagEmoji: String
    let price: Double
    let change: Double
    let changePercent: Double
    let sparklineData: [Double]
}

@MainActor
class QuotesViewModel: ObservableObject {
    @Published var recentSearches: [RecentSearchItem] = []
    @Published var marketQuotes: [Quote] = []
    @Published var isSearching = false
    @Published var lastUpdated = Date()

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm:ss a"
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        return "\(formatter.string(from: lastUpdated)) ET\nSome quotes delayed.\u{25C7}"
    }

    func search(symbol: String) async {
        guard !symbol.isEmpty else { return }
        isSearching = true
        defer { isSearching = false }

        do {
            let quote: Quote = try await APIService.shared.get("/quotes/\(symbol.uppercased())")
            let item = RecentSearchItem(
                symbol: quote.symbol,
                name: quote.symbol,
                flagEmoji: "🇨🇦",
                price: quote.currentPrice,
                change: quote.change,
                changePercent: quote.changePercent,
                sparklineData: generateSparkline(from: quote)
            )
            // Add to front, remove duplicates
            recentSearches.removeAll { $0.symbol == item.symbol }
            recentSearches.insert(item, at: 0)
            if recentSearches.count > 10 {
                recentSearches = Array(recentSearches.prefix(10))
            }
        } catch {}
    }

    func loadMarketOverview() async {
        do {
            marketQuotes = try await APIService.shared.get("/market/overview")
            lastUpdated = Date()
        } catch {}
    }

    func loadSampleRecentSearches() {
        if recentSearches.isEmpty {
            recentSearches = [
                RecentSearchItem(
                    symbol: "XEQT",
                    name: "iShares Core Equity ETF Portfolio",
                    flagEmoji: "🇨🇦",
                    price: 40.45,
                    change: 0.05,
                    changePercent: 0.12,
                    sparklineData: [40.2, 40.25, 40.3, 40.28, 40.35, 40.38, 40.4, 40.42, 40.45]
                ),
                RecentSearchItem(
                    symbol: "XGRO",
                    name: "iShares Core Growth ETF Portfolio",
                    flagEmoji: "🇨🇦",
                    price: 35.17,
                    change: 0.04,
                    changePercent: 0.11,
                    sparklineData: [35.3, 35.25, 35.15, 35.1, 35.08, 35.12, 35.14, 35.17]
                )
            ]
        }
    }

    private func generateSparkline(from quote: Quote) -> [Double] {
        // Generate simple sparkline data from quote info
        let base = quote.previousClose
        var points: [Double] = []
        let steps = 10
        for i in 0...steps {
            let progress = Double(i) / Double(steps)
            let value = base + (quote.currentPrice - base) * progress + Double.random(in: -0.5...0.5)
            points.append(value)
        }
        points[points.count - 1] = quote.currentPrice
        return points
    }
}
