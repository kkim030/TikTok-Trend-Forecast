import SwiftUI

struct RecommendationCardView: View {
    let rec: RecommendationResponse
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                // Confidence badge
                confidenceBadge

                // Title
                Text(rec.conceptTitle ?? "Untitled Concept")
                    .font(compact ? .appSubheadline : .appHeadline)
                    .fontWeight(.heavy)
                    .foregroundStyle(Color.primary)
                    .lineLimit(compact ? 2 : 3)

                if !compact {
                    // Description
                    if let desc = rec.conceptDescription {
                        Text(desc)
                            .font(.appCaption)
                            .foregroundStyle(Color.secondary)
                            .lineLimit(3)
                    }

                    // Music row
                    if let music = rec.suggestedMusic {
                        musicRow(music)
                    }

                    // Hashtags
                    if let tags = rec.suggestedHashtags, !tags.isEmpty {
                        hashtagRow(tags)
                    }
                } else {
                    // Compact: hashtags only
                    if let tags = rec.suggestedHashtags?.prefix(3), !tags.isEmpty {
                        hashtagRow(Array(tags))
                    }
                }
            }
            .padding(14)

            // Footer
            HStack {
                Text(rec.generatedAt.map { formatDate($0) } ?? "Just now")
                    .font(.appCaption2)
                    .foregroundStyle(Color.secondary)
                Spacer()
                Text("View full →")
                    .font(.appCaption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.tiktokAccent)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.tiktokBackground)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.tiktokPrimary.opacity(0.25), radius: 12, x: 0, y: 4)
    }

    // MARK: - Sub-views

    private var confidenceBadge: some View {
        let score = rec.confidenceScore ?? 0
        let (bg, fg): (Color, Color) = score >= 0.8
            ? (Color(hex: "#E8F5E9"), Color(hex: "#388E3C"))
            : score >= 0.6
            ? (Color(hex: "#FFF8E1"), Color(hex: "#F57F17"))
            : (Color.tiktokAccent.opacity(0.1), Color.tiktokDarkAccent)

        return HStack(spacing: 4) {
            Circle().fill(fg).frame(width: 6, height: 6)
            Text(String(format: "%.0f%% confident", score * 100))
                .font(.appCaption2)
                .fontWeight(.bold)
        }
        .foregroundStyle(fg)
        .padding(.horizontal, 9)
        .padding(.vertical, 3)
        .background(bg)
        .clipShape(Capsule())
    }

    private func musicRow(_ music: String) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(LinearGradient(colors: [.tiktokLavender, Color.purple.opacity(0.6)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 28, height: 28)
                .overlay(Image(systemName: "music.note").font(.appCaption2).foregroundStyle(.white))

            VStack(alignment: .leading, spacing: 1) {
                Text(music)
                    .font(.appCaption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.purple)
                    .lineLimit(1)
                Text("Trending now")
                    .font(.appCaption2)
                    .foregroundStyle(Color.secondary)
            }

            Spacer()

            Image(systemName: "play.circle.fill")
                .font(.title3)
                .foregroundStyle(Color.purple)
        }
        .padding(8)
        .background(Color.tiktokLavender.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func hashtagRow(_ tags: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    Text("#\(tag.hasPrefix("#") ? String(tag.dropFirst()) : tag)")
                        .font(.appCaption2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.tiktokAccent)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(Color.tiktokAccent.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let hours = Int(-date.timeIntervalSinceNow / 3600)
        if hours < 1 { return "Just now" }
        if hours < 24 { return "\(hours)h ago" }
        return "\(hours / 24)d ago"
    }
}
