import Foundation

enum HTTPMethod: String {
    case GET, POST, PUT, DELETE
}

enum APIEndpoint {
    // Auth
    case tiktokAuthorize
    case tiktokCallback
    case demoLogin

    // Trends
    case trends
    case musicTrends
    case hashtagTrends
    case categoryTrends
    case topTrends(type: String, limit: Int)
    case trendVideos(trendId: String, limit: Int)
    case categoryHashtags(category: String)

    // Recommendations
    case generateRecommendation
    case recommendations

    // Analytics
    case performanceAnalytics
    case videoAnalysis

    // Calendar
    case calendarEntries(month: String)
    case createCalendarEntry
    case updateCalendarEntry(id: String)
    case deleteCalendarEntry(id: String)
    case optimalTimes

    // MARK: - Path

    var path: String {
        switch self {
        case .tiktokAuthorize:           return "/api/v1/auth/tiktok/authorize"
        case .tiktokCallback:            return "/api/v1/auth/tiktok/callback"
        case .demoLogin:                 return "/api/v1/auth/demo"
        case .trends:                    return "/api/v1/trends"
        case .musicTrends:               return "/api/v1/trends/music"
        case .hashtagTrends:             return "/api/v1/trends/hashtags"
        case .categoryTrends:            return "/api/v1/trends/categories"
        case .topTrends:                 return "/api/v1/trends/top"
        case .trendVideos(let id, _):    return "/api/v1/trends/\(id)/videos"
        case .categoryHashtags(let cat): return "/api/v1/trends/categories/\(cat.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? cat)/hashtags"
        case .generateRecommendation:    return "/api/v1/recommendations"
        case .recommendations:           return "/api/v1/recommendations"
        case .performanceAnalytics:      return "/api/v1/analytics/performance"
        case .videoAnalysis:             return "/api/v1/analytics/video-analysis"
        case .calendarEntries:           return "/api/v1/calendar/entries"
        case .createCalendarEntry:       return "/api/v1/calendar/entries"
        case .updateCalendarEntry(let id): return "/api/v1/calendar/entries/\(id)"
        case .deleteCalendarEntry(let id): return "/api/v1/calendar/entries/\(id)"
        case .optimalTimes:              return "/api/v1/calendar/optimal-times"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .tiktokCallback, .demoLogin, .generateRecommendation, .videoAnalysis, .createCalendarEntry:
            return .POST
        case .updateCalendarEntry:
            return .PUT
        case .deleteCalendarEntry:
            return .DELETE
        default:
            return .GET
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .topTrends(let type, let limit):
            return [URLQueryItem(name: "type", value: type),
                    URLQueryItem(name: "limit", value: String(limit))]
        case .trendVideos(_, let limit):
            return [URLQueryItem(name: "limit", value: String(limit))]
        case .calendarEntries(let month):
            return [URLQueryItem(name: "month", value: month)]
        default:
            return nil
        }
    }
}
