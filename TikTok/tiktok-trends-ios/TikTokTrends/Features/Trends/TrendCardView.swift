import SwiftUI

// MARK: - Bento Card Sizes

enum CardSize { case wide, narrow, featured }

// MARK: - Trend Card

struct TrendCardView: View {
    let trend: TrendResponse
    var size: CardSize = .narrow
    @State private var isPlaying = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 8) {
                    typeBadge
                    Spacer(minLength: 0)
                    // Reserve room for the #1 pill so the badge doesn't slide under it.
                    if size == .featured {
                        Color.clear.frame(width: 92, height: 1)
                    }
                }
                .padding(.bottom, 8)

                if trend.trendType == "music" {
                    musicContent
                } else {
                    textContent
                }
            }
            .padding(size == .featured ? 18 : 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.tiktokPrimary.opacity(0.25), radius: 12, x: 0, y: 4)

            // #1 badge on featured (top-right)
            if size == .featured {
                PillBadge(text: "🔥 #1 Trending")
                    .padding(14)
            }

            // Play button on music cards — pinned bottom-right so it never collides
            // with the type badge (top-left) or the #1 pill (top-right).
            if trend.trendType == "music" {
                playButton
                    .padding(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }
    }

    // MARK: - Sub-views

    private var typeBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: trend.trendType.trendTypeIcon)
                .font(.appCaption2)
            Text(trend.trendType.trendTypeLabel)
                .font(.appCaption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(trend.trendType == "hashtag" ? Color.tiktokAccent :
                         trend.trendType == "music"   ? Color.tiktokLavender.mix(with: .purple, by: 0.4) :
                                                        Color.tiktokMint.mix(with: .teal, by: 0.4))
        .padding(.horizontal, 9)
        .padding(.vertical, 3)
        .background(
            trend.trendType == "hashtag" ? Color.tiktokAccent.opacity(0.1) :
            trend.trendType == "music"   ? Color.tiktokLavender.opacity(0.4) :
                                           Color.tiktokMint.opacity(0.4)
        )
        .clipShape(Capsule())
    }

    private var textContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(trend.keyword)
                .font(size == .featured ? .appTitle2 : .appHeadline)
                .foregroundStyle(Color.primary)
                .lineLimit(2)

            if let velocity = trend.velocityScore {
                velocityBar(value: velocity)
            }

            HStack(spacing: 10) {
                if let views = trend.viewCountAvg {
                    Label(formatViews(views), systemImage: "eye.fill")
                        .font(.appCaption2)
                        .foregroundStyle(Color.secondary)
                }
                if let eng = trend.engagementAvg {
                    Label(String(format: "%.1f%%", eng * 100), systemImage: "heart.fill")
                        .font(.appCaption2)
                        .foregroundStyle(Color.secondary)
                }
                VelocityFlame(score: trend.velocityScore ?? 0)
            }
        }
    }

    private var musicContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Cover art placeholder
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(colors: [Color.tiktokLavender, Color.purple.opacity(0.6)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.title3)
                        .foregroundStyle(.white)
                )
                .padding(.bottom, 2)

            Text(trend.keyword)
                .font(.appHeadline)
                .foregroundStyle(Color.primary)
                .lineLimit(1)

            if let artist = trend.musicArtist {
                Text(artist)
                    .font(.appCaption)
                    .foregroundStyle(Color.secondary)
            }

            VelocityFlame(score: trend.velocityScore ?? 0)
                .padding(.top, 2)
        }
        .padding(.trailing, 40) // room for play button
    }

    private var playButton: some View {
        Button {
            isPlaying.toggle()
            // AVPlayer logic will hook in here in Phase 6
        } label: {
            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                .font(.system(size: 30))
                .foregroundStyle(isPlaying ? Color.purple : Color.tiktokAccent)
                .symbolEffect(.bounce, value: isPlaying)
        }
        .buttonStyle(IconButtonStyle())
    }

    private func velocityBar(value: Double) -> some View {
        let pct = min(max(value / 100.0, 0), 1.0)
        return VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("Velocity")
                    .font(.appCaption2)
                    .foregroundStyle(Color.secondary)
                Spacer()
                Text("+\(Int(value))%")
                    .font(.appCaption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.tiktokAccent)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.tiktokBackground).frame(height: 5)
                    Capsule()
                        .fill(LinearGradient(colors: [.tiktokPrimary, .tiktokAccent],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * pct, height: 5)
                }
            }
            .frame(height: 5)
        }
    }

    private func formatViews(_ n: Int) -> String {
        switch n {
        case 1_000_000...: return String(format: "%.1fM", Double(n) / 1_000_000)
        case 1_000...:     return String(format: "%.0fK", Double(n) / 1_000)
        default:           return "\(n)"
        }
    }
}
