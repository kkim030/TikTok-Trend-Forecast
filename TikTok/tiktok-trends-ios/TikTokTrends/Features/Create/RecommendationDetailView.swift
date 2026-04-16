import SwiftUI

struct RecommendationDetailView: View {
    let rec: RecommendationResponse
    @State private var showCalendarSheet = false
    @State private var copiedTag: String?

    var body: some View {
        ZStack {
            Color.tiktokBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    confidenceSection
                    conceptSection
                    if let music = rec.suggestedMusic { musicSection(music) }
                    if let tags = rec.suggestedHashtags, !tags.isEmpty { hashtagSection(tags) }
                    scheduleButton
                }
                .padding(16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("AI Concept")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCalendarSheet) {
            CalendarEntrySheet(prefilledTitle: rec.conceptTitle)
        }
    }

    // MARK: - Confidence

    private var confidenceSection: some View {
        let score = rec.confidenceScore ?? 0
        return HStack(spacing: 16) {
            // Circular gauge
            ZStack {
                Circle()
                    .stroke(Color.tiktokBackground, lineWidth: 8)
                    .frame(width: 70, height: 70)
                Circle()
                    .trim(from: 0, to: score)
                    .stroke(Color.tiktokAccent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 70, height: 70)
                    .shadow(color: Color.tiktokAccent.opacity(0.3), radius: 6)
                VStack(spacing: 0) {
                    Text(String(format: "%.0f%%", score * 100))
                        .font(.appSubheadline).fontWeight(.black).foregroundStyle(Color.tiktokAccent)
                    Text("score").font(.appCaption2).foregroundStyle(Color.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Confidence Score")
                    .font(.appSubheadline).fontWeight(.bold).foregroundStyle(Color.tiktokDarkAccent)
                Text(score >= 0.8
                     ? "High likelihood of strong performance based on current trends."
                     : score >= 0.6
                     ? "Moderate confidence — trend is active but competitive."
                     : "Emerging trend — high risk, high reward.")
                    .font(.appCaption)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(3)
            }
        }
        .pinkCard()
    }

    // MARK: - Concept

    private var conceptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Concept", systemImage: "sparkles")
                .font(.appCaption).fontWeight(.bold)
                .foregroundStyle(Color.tiktokAccent)
                .textCase(.uppercase)

            Text(rec.conceptTitle ?? "Untitled")
                .font(.appTitle2).fontWeight(.black).foregroundStyle(Color.primary)

            if let desc = rec.conceptDescription {
                Text(desc)
                    .font(.appBody).foregroundStyle(Color.secondary).lineSpacing(3)
            }
        }
        .pinkCard()
    }

    // MARK: - Music

    private func musicSection(_ music: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Suggested Music", systemImage: "music.note")
                .font(.appCaption).fontWeight(.bold)
                .foregroundStyle(Color.purple)
                .textCase(.uppercase)

            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LinearGradient(colors: [.tiktokLavender, .purple.opacity(0.7)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                    .overlay(Image(systemName: "music.note").font(.title3).foregroundStyle(.white))

                VStack(alignment: .leading, spacing: 2) {
                    Text(music).font(.appSubheadline).fontWeight(.bold).foregroundStyle(Color.purple)
                    Text("Trending now").font(.appCaption2).foregroundStyle(Color.secondary)
                }

                Spacer()

                Button {
                    // AVPlayer preview — Phase 6
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.purple)
                }
                .buttonStyle(IconButtonStyle())
            }
        }
        .pinkCard()
    }

    // MARK: - Hashtags

    private func hashtagSection(_ tags: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Hashtags", systemImage: "number")
                    .font(.appCaption).fontWeight(.bold)
                    .foregroundStyle(Color.tiktokAccent)
                    .textCase(.uppercase)
                Spacer()
                Button("Copy All") {
                    let all = tags.map { "#\($0.hasPrefix("#") ? String($0.dropFirst()) : $0)" }.joined(separator: " ")
                    UIPasteboard.general.string = all
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                .font(.appCaption).fontWeight(.bold)
                .foregroundStyle(Color.tiktokAccent)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .overlay(Capsule().strokeBorder(Color.tiktokAccent, lineWidth: 1.5))
            }

            FlowLayout(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    let display = "#\(tag.hasPrefix("#") ? String(tag.dropFirst()) : tag)"
                    Button {
                        UIPasteboard.general.string = display
                        copiedTag = tag
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copiedTag = nil }
                    } label: {
                        Text(copiedTag == tag ? "✓ Copied!" : display)
                            .font(.appCaption).fontWeight(.bold)
                            .foregroundStyle(copiedTag == tag ? .white : Color.tiktokAccent)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(copiedTag == tag ? Color.tiktokAccent : Color.tiktokAccent.opacity(0.1))
                            .clipShape(Capsule())
                            .animation(.spring(response: 0.2), value: copiedTag)
                    }
                    .buttonStyle(IconButtonStyle())
                }
            }

            Text("Tap a hashtag to copy · Copy All to get all at once")
                .font(.appCaption2).foregroundStyle(Color.secondary)
        }
        .pinkCard()
    }

    // MARK: - Schedule

    private var scheduleButton: some View {
        Button { showCalendarSheet = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.plus")
                Text("Schedule This Video")
            }
            .font(.appHeadline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                LinearGradient(colors: [.tiktokMint.mix(with: .teal, by: 0.3), Color.teal],
                               startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.teal.opacity(0.35), radius: 12, x: 0, y: 5)
        }
    }
}

// MARK: - Simple flow layout for hashtags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0 }.reduce(0) { $0 + $1 + spacing }
        return CGSize(width: proposal.width ?? 0, height: max(height - spacing, 0))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: ProposedViewSize(width: bounds.width, height: nil), subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for view in row {
                let size = view.sizeThatFits(.unspecified)
                view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var x: CGFloat = 0
        let maxW = proposal.width ?? .infinity
        for view in subviews {
            let w = view.sizeThatFits(.unspecified).width
            if x + w > maxW, !rows[rows.endIndex - 1].isEmpty {
                rows.append([])
                x = 0
            }
            rows[rows.endIndex - 1].append(view)
            x += w + spacing
        }
        return rows
    }
}
