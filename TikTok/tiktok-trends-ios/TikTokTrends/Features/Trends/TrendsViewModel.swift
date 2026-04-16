import Foundation

enum TrendSegment: String, CaseIterable {
    case all      = "All"
    case hashtag  = "# Hashtag"
    case music    = "♪ Music"
    case category = "⊞ Category"
}

@Observable
final class TrendsViewModel {
    var trends: [TrendResponse] = []
    var isLoading = false
    var errorMessage: String?
    var selectedSegment: TrendSegment = .all

    var displayedTrends: [TrendResponse] {
        switch selectedSegment {
        case .all:      return trends
        case .hashtag:  return trends.filter { $0.trendType == "hashtag" }
        case .music:    return trends.filter { $0.trendType == "music" }
        case .category: return trends.filter { $0.trendType == "content_category" }
        }
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            trends = try await APIClient.shared.request(.trends)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() async {
        trends = []
        await load()
    }
}
