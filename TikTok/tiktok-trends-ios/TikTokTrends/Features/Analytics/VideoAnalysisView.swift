import SwiftUI

struct VideoAnalysisView: View {
    @State private var analysis: VideoAnalysisResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.tiktokBackground.ignoresSafeArea()

            if isLoading {
                loadingView
            } else if let analysis {
                resultView(analysis)
            } else if let error = errorMessage {
                ContentUnavailableView(error, systemImage: "brain")
            }
        }
        .navigationTitle("Why Your Videos Perform 🌟")
        .navigationBarTitleDisplayMode(.large)
        .task { await load() }
    }

    // MARK: - Loading

    private var loadingView: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Analyzing your videos...")
                        .font(.appHeadline)
                        .foregroundStyle(Color.tiktokDarkAccent)
                    Text("Claude is reviewing your top performers vs. current trends")
                        .font(.appCaption)
                        .foregroundStyle(Color.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .pinkCard()

                // Shimmer placeholders
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 16).fill(Color.white)
                        .frame(height: 80)
                        .shimmer()
                }
            }
            .padding(16)
        }
    }

    // MARK: - Result

    private func resultView(_ data: VideoAnalysisResponse) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                // Top videos
                VStack(alignment: .leading, spacing: 10) {
                    Text("🎬 Your Top Videos")
                        .font(.appHeadline)
                        .foregroundStyle(Color.tiktokDarkAccent)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(data.topVideos) { video in
                                VideoSummaryCard(video: video)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .pinkCard()

                // Claude analysis (markdown)
                if let text = data.analysis {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🧠 Claude's Analysis")
                            .font(.appHeadline)
                            .foregroundStyle(Color.purple)

                        if let attributed = try? AttributedString(markdown: text) {
                            Text(attributed)
                                .font(.appBody)
                                .foregroundStyle(Color.primary)
                        } else {
                            Text(text)
                                .font(.appBody)
                                .foregroundStyle(Color.primary)
                        }
                    }
                    .pinkCard()
                }

                // Key takeaways
                if !data.keyTakeaways.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("💡 Key Takeaways")
                            .font(.appHeadline)
                            .foregroundStyle(Color.tiktokDarkAccent)

                        ForEach(Array(data.keyTakeaways.enumerated()), id: \.offset) { _, takeaway in
                            HStack(alignment: .top, spacing: 10) {
                                Text("✦")
                                    .foregroundStyle(Color.tiktokAccent)
                                    .font(.appCallout)
                                Text(takeaway)
                                    .font(.appSubheadline)
                                    .foregroundStyle(Color.primary)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.tiktokBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .pinkCard()
                }

                if let date = data.analyzedAt {
                    Text("Analyzed \(date.formatted(date: .abbreviated, time: .shortened)) · Refreshes in 24h")
                        .font(.appCaption2)
                        .foregroundStyle(Color.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                Spacer(minLength: 32)
            }
            .padding(16)
        }
    }

    // MARK: - Load

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            analysis = try await APIClient.shared.request(.videoAnalysis)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Video Summary Card

struct VideoSummaryCard: View {
    let video: VideoSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: URL(string: video.thumbnailUrl ?? "")) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                LinearGradient(colors: [.tiktokPrimary, .tiktokAccent],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            .frame(width: 100, height: 130)
            .clipped()
            .overlay(alignment: .topTrailing) {
                if let views = video.viewCount {
                    Text(formatNum(views))
                        .font(.appCaption2).fontWeight(.bold).foregroundStyle(.white)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Color.black.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .padding(5)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(video.title ?? "Video")
                    .font(.appCaption2).fontWeight(.bold).lineLimit(1)
                if let eng = video.engagementRate {
                    Text(String(format: "%.1f%% eng.", eng * 100))
                        .font(.appCaption2).foregroundStyle(Color.secondary)
                }
            }
            .padding(8)
            .background(Color.white)
        }
        .frame(width: 100)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.tiktokPrimary.opacity(0.25), radius: 8, x: 0, y: 3)
    }

    private func formatNum(_ n: Int) -> String {
        n >= 1_000_000 ? String(format: "%.1fM", Double(n)/1_000_000)
        : n >= 1_000   ? String(format: "%.0fK", Double(n)/1_000)
        : "\(n)"
    }
}
