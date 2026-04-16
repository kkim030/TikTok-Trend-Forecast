import SwiftUI

struct OptimalTimingView: View {
    @State private var timing: OptimalTimingResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let days   = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    private let dayKeys = ["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"]
    private let displayHours = [0, 6, 9, 12, 15, 18, 21]

    var body: some View {
        ZStack {
            Color.tiktokBackground.ignoresSafeArea()
            if isLoading {
                ProgressView().tint(Color.tiktokAccent)
            } else if let timing {
                content(timing)
            } else if let error = errorMessage {
                ContentUnavailableView(error, systemImage: "clock.badge.exclamationmark")
            }
        }
        .navigationTitle("Best Times to Post 🕐")
        .navigationBarTitleDisplayMode(.large)
        .task { await load() }
    }

    private func content(_ data: OptimalTimingResponse) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Subtitle
                Text("Based on your 6-month engagement history")
                    .font(.appSubheadline)
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Heatmap
                heatmapCard(data.heatmap)

                // Best slots
                bestSlotsCard(data.bestSlots)
            }
            .padding(16)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Heatmap

    private func heatmapCard(_ heatmap: [String: [Double]]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Engagement Heatmap")
                .font(.appHeadline)
                .foregroundStyle(Color.tiktokDarkAccent)

            // Day headers
            HStack(spacing: 0) {
                Text("").frame(width: 36)
                ForEach(days, id: \.self) { d in
                    Text(d)
                        .font(.appCaption2).fontWeight(.bold)
                        .foregroundStyle(Color.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Rows
            ForEach(displayHours, id: \.self) { hour in
                HStack(spacing: 4) {
                    Text(hourLabel(hour))
                        .font(.appCaption2).foregroundStyle(Color.secondary)
                        .frame(width: 32, alignment: .trailing)

                    ForEach(Array(dayKeys.enumerated()), id: \.offset) { _, key in
                        let val = heatmap[key]?[safe: hour] ?? 0
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(heatColor(val))
                            .frame(maxWidth: .infinity)
                            .frame(height: 18)
                    }
                }
            }

            // Legend
            HStack(spacing: 8) {
                Text("Low")
                    .font(.appCaption2).foregroundStyle(Color.secondary)
                LinearGradient(colors: [Color.tiktokBackground, Color.tiktokPrimary, Color.tiktokAccent],
                               startPoint: .leading, endPoint: .trailing)
                    .frame(height: 8)
                    .clipShape(Capsule())
                Text("High")
                    .font(.appCaption2).foregroundStyle(Color.secondary)
            }
            .padding(.top, 4)
        }
        .pinkCard()
    }

    // MARK: - Best slots

    private func bestSlotsCard(_ slots: [TimeSlot]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Top 5 Slots This Week")
                .font(.appHeadline)
                .foregroundStyle(Color.tiktokDarkAccent)

            ForEach(Array(slots.prefix(5).enumerated()), id: \.offset) { i, slot in
                HStack {
                    Text("\(i + 1)")
                        .font(.appCaption2).fontWeight(.black)
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(i == 0 ? Color.tiktokAccent : Color.tiktokPrimary)
                        .clipShape(Circle())

                    Text("\(slot.dayOfWeek.capitalized) · \(hourLabel(slot.hour))")
                        .font(.appSubheadline).fontWeight(.bold).foregroundStyle(Color.primary)

                    Spacer()

                    Text(String(format: "Predicted +%.0f%%", slot.predictedEngagement * 100))
                        .font(.appCaption2).fontWeight(.bold)
                        .foregroundStyle(Color.tiktokAccent)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.tiktokAccent.opacity(0.1))
                        .clipShape(Capsule())
                }
                .padding(12)
                .background(Color.tiktokBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .pinkCard()
    }

    // MARK: - Helpers

    private func heatColor(_ value: Double) -> Color {
        if value > 0.7 { return Color.tiktokAccent }
        if value > 0.4 { return Color.tiktokPrimary }
        return Color.tiktokBackground
    }

    private func hourLabel(_ hour: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        return "\(h)\(hour < 12 ? "am" : "pm")"
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            timing = try await APIClient.shared.request(.optimalTimes)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
