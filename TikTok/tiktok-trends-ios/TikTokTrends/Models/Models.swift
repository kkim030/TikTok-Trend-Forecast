import Foundation

// MARK: - Auth

struct AuthResponse: Codable {
    let token: String
    let userId: String
    let tiktokHandle: String
    let niche: String?
    let displayName: String?
    let avatarUrl: String?
}

struct TikTokCallbackRequest: Codable {
    let code: String
    let state: String
}

// MARK: - Trends

struct TrendResponse: Codable, Identifiable {
    let id: String
    let trendType: String
    let keyword: String
    let velocityScore: Double?
    let engagementAvg: Double?
    let viewCountAvg: Int?
    let detectedAt: Date?
    let expiresAt: Date?
    // Phase 6 — music preview fields (nullable until backend adds V5 migration)
    let musicPreviewUrl: String?
    let musicArtist: String?
    let musicCoverArtUrl: String?
}

struct TrendVideoResponse: Codable, Identifiable {
    let videoId: String
    let thumbnailUrl: String?
    let viewCount: Int?
    let likeCount: Int?
    let shareCount: Int?
    let creatorHandle: String?
    let creatorAvatarUrl: String?
    let description: String?
    let videoUrl: String?
    let publishedAt: Date?

    var id: String { videoId }
}

struct TrendVideosWrapper: Codable {
    let trendId: String
    let videos: [TrendVideoResponse]
}

// MARK: - Recommendations

struct RecommendationResponse: Codable, Identifiable {
    let id: String
    let conceptTitle: String?
    let conceptDescription: String?
    let suggestedMusic: String?
    let suggestedHashtags: [String]?
    let confidenceScore: Double?
    let generatedAt: Date?
}

// MARK: - Analytics

struct PerformanceComparisonResponse: Codable {
    let userSnapshots: [PerformanceSnapshotResponse]
    let benchmarks: [PerformanceSnapshotResponse]
    let currentGrades: KpiGradeResponse?
}

struct PerformanceSnapshotResponse: Codable, Identifiable {
    let periodStart: Date?
    let periodEnd: Date?
    let engagementRate: Double?
    let viewVelocity: Double?
    let followerGrowthRate: Double?
    let avgWatchTimePct: Double?
    let shareRate: Double?
    let followerCount: Int?
    let totalViews: Int?

    var id: String { "\(periodStart?.timeIntervalSince1970 ?? 0)" }
}

struct KpiGradeResponse: Codable {
    let engagementRate: String?
    let viewVelocity: String?
    let followerGrowth: String?
    let watchTime: String?
    let shareRate: String?
    let overall: String?
}

struct VideoAnalysisResponse: Codable, Identifiable {
    let id: String
    let analyzedAt: Date?
    let topVideos: [VideoSummary]
    let analysis: String?          // markdown
    let keyTakeaways: [String]
}

struct VideoSummary: Codable, Identifiable {
    let videoId: String
    let title: String?
    let viewCount: Int?
    let engagementRate: Double?
    let thumbnailUrl: String?

    var id: String { videoId }
}

// MARK: - Calendar

struct CalendarEntryResponse: Codable, Identifiable {
    let id: String
    let title: String
    let notes: String?
    let scheduledAt: Date?
    let status: String     // "draft" | "scheduled" | "posted"
    let recommendationId: String?
}

struct CalendarEntryRequest: Codable {
    let title: String
    let notes: String?
    let scheduledAt: Date
    let status: String
    let recommendationId: String?
}

struct OptimalTimingResponse: Codable {
    let bestSlots: [TimeSlot]
    let heatmap: [String: [Double]]   // "MONDAY": [0.02, 0.01, ...]
}

struct TimeSlot: Codable, Identifiable {
    let dayOfWeek: String
    let hour: Int
    let predictedEngagement: Double

    var id: String { "\(dayOfWeek)-\(hour)" }
}
