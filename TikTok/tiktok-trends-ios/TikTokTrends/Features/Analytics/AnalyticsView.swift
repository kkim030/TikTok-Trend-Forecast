import SwiftUI

struct AnalyticsView: View {
    @State private var vm = AnalyticsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tiktokBackground.ignoresSafeArea()

                if vm.isLoading && vm.comparison == nil {
                    loadingSkeleton
                } else if let error = vm.errorMessage {
                    ContentUnavailableView(error, systemImage: "chart.bar.xaxis")
                } else {
                    content
                }
            }
            .navigationTitle("Analytics 📊")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AvatarButton()
                }
            }
            .task { await vm.load() }
        }
    }

    // MARK: - Main Content

    private var content: some View {
        ScrollView {
            VStack(spacing: 14) {
                kpiCardsSection
                chartSection
                overallGradeCard
                aiAnalyzeButton
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .refreshable { await vm.load() }
    }

    // MARK: - KPI Cards

    private var kpiCardsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your KPI Grades")
                .font(.appHeadline)
                .foregroundStyle(Color.tiktokDarkAccent)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(KpiMetric.allCases) { metric in
                        KpiScoreCardView(
                            metric: metric,
                            grade: metric.grade(from: vm.currentGrades),
                            value: metricValueString(metric),
                            isSelected: vm.selectedMetric == metric
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                vm.selectedMetric = metric
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Chart

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📈 \(vm.selectedMetric.rawValue)")
                    .font(.appHeadline)
                    .foregroundStyle(Color.tiktokDarkAccent)
                Spacer()
                Button {
                    withAnimation { vm.showBenchmark.toggle() }
                } label: {
                    Text("vs Benchmark")
                        .font(.appCaption)
                        .fontWeight(.bold)
                        .foregroundStyle(vm.showBenchmark ? .white : Color.tiktokAccent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(vm.showBenchmark ? Color.tiktokAccent : Color.tiktokAccent.opacity(0.1))
                        )
                }
            }

            PerformanceChartView(
                userSeries: vm.userSeries,
                benchmarkSeries: vm.benchmarkSeries,
                metricName: vm.selectedMetric.rawValue,
                showBenchmark: vm.showBenchmark
            )
        }
        .pinkCard()
    }

    // MARK: - Overall Grade

    private var overallGradeCard: some View {
        HStack(spacing: 16) {
            // Grade circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.tiktokAccent, .tiktokDarkAccent],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: Color.tiktokAccent.opacity(0.4), radius: 12, x: 0, y: 4)

                Text(vm.overallGrade)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Overall Grade")
                    .font(.appTitle3)
                    .foregroundStyle(Color.tiktokDarkAccent)
                Text(overallTip)
                    .font(.appCaption)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(2)
            }
        }
        .padding(18)
        .background(
            LinearGradient(colors: [Color.tiktokAccent.opacity(0.08), Color.tiktokBackground],
                           startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.tiktokPrimary, lineWidth: 1.5)
        )
    }

    // MARK: - AI Button

    private var aiAnalyzeButton: some View {
        NavigationLink(destination: VideoAnalysisView()) {
            HStack(spacing: 12) {
                Text("🧠")
                    .font(.title)
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Analyze My Videos ✨")
                        .font(.appHeadline)
                        .foregroundStyle(.white)
                    Text("Claude explains why your top videos performed well")
                        .font(.appCaption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(16)
            .background(
                LinearGradient(colors: [Color.purple.opacity(0.8), Color.tiktokAccent],
                               startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.purple.opacity(0.35), radius: 14, x: 0, y: 6)
        }
    }

    // MARK: - Loading skeleton

    private var loadingSkeleton: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 18).fill(Color.white)
                        .frame(width: 100, height: 110).shimmer()
                }
            }
            .padding(.horizontal, 16)
            RoundedRectangle(cornerRadius: 20).fill(Color.white)
                .frame(height: 180).padding(.horizontal, 16).shimmer()
            RoundedRectangle(cornerRadius: 20).fill(Color.white)
                .frame(height: 90).padding(.horizontal, 16).shimmer()
        }
        .padding(.top, 16)
    }

    // MARK: - Helpers

    private func metricValueString(_ metric: KpiMetric) -> String {
        guard let latest = vm.comparison?.userSnapshots.last else { return "—" }
        guard let val = metric.value(from: latest) else { return "—" }
        switch metric {
        case .engagementRate, .shareRate:
            return String(format: "%.1f%%", val * 100)
        case .viewVelocity, .followerGrowth:
            return String(format: "+%.0f%%", val)
        case .watchTime:
            return String(format: "%.0f%%", val)
        }
    }

    private var overallTip: String {
        switch vm.overallGrade {
        case "A": return "Outstanding! You're a top creator in your niche."
        case "B": return "Above average. Push your share rate to reach an A."
        case "C": return "On track. Focus on engagement and watch time."
        case "D": return "Room to grow. Try trending sounds and peak posting times."
        default:  return "Keep going! Consistency is key."
        }
    }
}
