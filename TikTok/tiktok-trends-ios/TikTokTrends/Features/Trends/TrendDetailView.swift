import SwiftUI

struct TrendDetailView: View {
    let trend: TrendResponse
    @State private var videos: [TrendVideoResponse] = []
    @State private var categoryHashtags: [TrendResponse] = []
    @State private var isLoadingVideos = false

    private var isCategory: Bool { trend.trendType == "content_category" }

    var body: some View {
        ZStack {
            Color.tiktokBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    heroCard
                    if isCategory && !categoryHashtags.isEmpty { categoryHashtagsSection }
                    if !videos.isEmpty { topTikToksSection }
                    velocitySection
                    ctaButton
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(trend.keyword)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadVideos()
            if isCategory { await loadCategoryHashtags() }
        }
    }

    // MARK: - Category Hashtags

    private var categoryHashtagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("# Trending hashtags in \(trend.keyword)")
                .font(.appHeadline)
                .foregroundStyle(Color.tiktokDarkAccent)

            VStack(spacing: 8) {
                ForEach(categoryHashtags) { hashtag in
                    NavigationLink(destination: TrendDetailView(trend: hashtag)) {
                        HStack {
                            Text("#\(hashtag.keyword)")
                                .font(.appSubheadline).fontWeight(.bold)
                                .foregroundStyle(Color.tiktokAccent)
                            Spacer()
                            if let v = hashtag.velocityScore {
                                Text("+\(Int(v))%")
                                    .font(.appCaption2).fontWeight(.bold)
                                    .foregroundStyle(Color.tiktokAccent)
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(Color.tiktokAccent.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            Image(systemName: "chevron.right")
                                .font(.appCaption2)
                                .foregroundStyle(Color.secondary)
                        }
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .pinkCard()
    }

    private func loadCategoryHashtags() async {
        do {
            categoryHashtags = try await APIClient.shared.request(.categoryHashtags(category: trend.keyword))
        } catch {
            // Silently fail — section just won't show
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Type badge
            HStack(spacing: 5) {
                Image(systemName: trend.trendType.trendTypeIcon)
                Text(trend.trendType.trendTypeLabel)
            }
            .font(.appSubheadline)
            .fontWeight(.semibold)
            .foregroundStyle(trend.trendType == "music" ? Color.purple : Color.tiktokAccent)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(trend.trendType == "music"
                               ? Color.tiktokLavender.opacity(0.5)
                               : Color.tiktokAccent.opacity(0.1))
            )

            // Keyword
            Text(trend.keyword)
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(Color.primary)

            // Pill tags
            HStack(spacing: 8) {
                PillBadge(text: "🔥 Trending")
                if let detected = trend.detectedAt {
                    PillBadge(text: "Detected \(detected.daysAgo)",
                              color: Color.tiktokPrimary.opacity(0.4),
                              foreground: Color.tiktokDarkAccent)
                }
            }

            // Stat tiles
            HStack(spacing: 8) {
                statTile(value: velocity, label: "Velocity", color: .tiktokAccent)
                statTile(value: engagement, label: "Engagement", color: .tiktokAccent)
                statTile(value: views, label: "Avg Views", color: .tiktokAccent)
            }
        }
        .pinkCard()
    }

    // MARK: - Top TikToks

    private var topTikToksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("🎬 Top TikToks")
                    .font(.appHeadline)
                    .foregroundStyle(Color.tiktokDarkAccent)
                Spacer()
                Text("See all →")
                    .font(.appCaption)
                    .foregroundStyle(Color.tiktokAccent)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(videos) { video in
                        VideoThumbCard(video: video)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Velocity sparkline (placeholder — Phase 6 will wire real data)

    private var velocitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📈 7-Day Velocity")
                .font(.appHeadline)
                .foregroundStyle(Color.tiktokDarkAccent)

            // Simple decorative chart shape
            GeometryReader { geo in
                let w = geo.size.width
                Path { p in
                    p.move(to: CGPoint(x: 0, y: 50))
                    p.addCurve(to: CGPoint(x: w, y: 4),
                               control1: CGPoint(x: w * 0.3, y: 35),
                               control2: CGPoint(x: w * 0.7, y: 10))
                }
                .stroke(
                    LinearGradient(colors: [.tiktokPrimary, .tiktokAccent],
                                   startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
            }
            .frame(height: 56)
        }
        .pinkCard()
    }

    // MARK: - CTA

    private var ctaButton: some View {
        NavigationLink(destination: CreateView()) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Create with this trend")
                        .font(.appHeadline)
                        .foregroundStyle(.white)
                    Text("Get an AI video concept →")
                        .font(.appCaption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                Text("✨")
                    .font(.title)
            }
            .padding(18)
            .background(
                LinearGradient(colors: [.tiktokAccent, .tiktokDarkAccent],
                               startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.tiktokAccent.opacity(0.4), radius: 14, x: 0, y: 6)
        }
    }

    // MARK: - Helpers

    private var velocity: String {
        guard let v = trend.velocityScore else { return "—" }
        return "+\(Int(v))%"
    }

    private var engagement: String {
        guard let e = trend.engagementAvg else { return "—" }
        return String(format: "%.1f%%", e * 100)
    }

    private var views: String {
        guard let v = trend.viewCountAvg else { return "—" }
        switch v {
        case 1_000_000...: return String(format: "%.0fM", Double(v) / 1_000_000)
        case 1_000...:     return String(format: "%.0fK", Double(v) / 1_000)
        default:           return "\(v)"
        }
    }

    private func statTile(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.appTitle3)
                .fontWeight(.black)
                .foregroundStyle(color)
            Text(label)
                .font(.appCaption2)
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.tiktokBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func loadVideos() async {
        isLoadingVideos = true
        defer { isLoadingVideos = false }
        do {
            let wrapper: TrendVideosWrapper = try await APIClient.shared.request(
                .trendVideos(trendId: trend.id, limit: 10)
            )
            videos = wrapper.videos
        } catch {
            // Silently fail — videos section just won't show
        }
    }
}

// MARK: - Video Thumbnail Card

struct VideoThumbCard: View {
    let video: TrendVideoResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: video.thumbnailUrl ?? "")) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    LinearGradient(colors: [.tiktokPrimary, .tiktokAccent],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                }
                .frame(width: 110, height: 148)
                .clipped()

                if let views = video.viewCount {
                    Text(formatViews(views))
                        .font(.appCaption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(6)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("@\(video.creatorHandle ?? "creator")")
                    .font(.appCaption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                if let likes = video.likeCount {
                    Label(formatViews(likes), systemImage: "heart.fill")
                        .font(.appCaption2)
                        .foregroundStyle(Color.secondary)
                }
            }
            .padding(8)
        }
        .frame(width: 110)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.tiktokPrimary.opacity(0.25), radius: 8, x: 0, y: 3)
        .onTapGesture { openVideo() }
    }

    private func openVideo() {
        guard let urlStr = video.videoUrl, let url = URL(string: urlStr) else { return }
        UIApplication.shared.open(url)
    }

    private func formatViews(_ n: Int) -> String {
        switch n {
        case 1_000_000...: return String(format: "%.1fM", Double(n) / 1_000_000)
        case 1_000...:     return String(format: "%.0fK", Double(n) / 1_000)
        default:           return "\(n)"
        }
    }
}

// MARK: - Date extension

extension Date {
    var daysAgo: String {
        let days = Calendar.current.dateComponents([.day], from: self, to: .now).day ?? 0
        return days == 0 ? "today" : "\(days)d ago"
    }
}
