import Foundation
import UIKit

@Observable
final class CreateViewModel {
    var recommendations: [RecommendationResponse] = []
    var isGenerating = false
    var isLoading = false
    var errorMessage: String?

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            recommendations = try await APIClient.shared.request(.recommendations)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func generate() async {
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }
        do {
            let new: RecommendationResponse = try await APIClient.shared.request(.generateRecommendation)
            recommendations.insert(new, at: 0)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
