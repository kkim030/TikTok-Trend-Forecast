import Foundation

enum KpiMetric: String, CaseIterable, Identifiable {
    case engagementRate  = "Engagement Rate"
    case viewVelocity    = "View Velocity"
    case followerGrowth  = "Follower Growth"
    case watchTime       = "Watch Time"
    case shareRate       = "Share Rate"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .engagementRate: return "heart.fill"
        case .viewVelocity:   return "eye.fill"
        case .followerGrowth: return "person.badge.plus.fill"
        case .watchTime:      return "clock.fill"
        case .shareRate:      return "arrowshape.turn.up.right.fill"
        }
    }

    func grade(from grades: KpiGradeResponse?) -> String {
        switch self {
        case .engagementRate: return grades?.engagementRate ?? "—"
        case .viewVelocity:   return grades?.viewVelocity   ?? "—"
        case .followerGrowth: return grades?.followerGrowth ?? "—"
        case .watchTime:      return grades?.watchTime      ?? "—"
        case .shareRate:      return grades?.shareRate      ?? "—"
        }
    }

    func value(from snapshot: PerformanceSnapshotResponse?) -> Double? {
        switch self {
        case .engagementRate: return snapshot?.engagementRate
        case .viewVelocity:   return snapshot?.viewVelocity
        case .followerGrowth: return snapshot?.followerGrowthRate
        case .watchTime:      return snapshot?.avgWatchTimePct
        case .shareRate:      return snapshot?.shareRate
        }
    }
}

@Observable
final class AnalyticsViewModel {
    var comparison: PerformanceComparisonResponse?
    var isLoading = false
    var errorMessage: String?
    var selectedMetric: KpiMetric = .engagementRate
    var showBenchmark = false

    var currentGrades: KpiGradeResponse? { comparison?.currentGrades }
    var overallGrade: String { currentGrades?.overall ?? "—" }

    var userSeries: [Double] {
        comparison?.userSnapshots.compactMap { selectedMetric.value(from: $0) } ?? []
    }

    var benchmarkSeries: [Double] {
        comparison?.benchmarks.compactMap { selectedMetric.value(from: $0) } ?? []
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            comparison = try await APIClient.shared.request(.performanceAnalytics)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
