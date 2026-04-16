import SwiftUI
import Charts

struct PerformanceChartView: View {
    let userSeries: [Double]
    let benchmarkSeries: [Double]
    let metricName: String
    var showBenchmark: Bool = false

    private var userPoints: [ChartPoint] {
        userSeries.enumerated().map { ChartPoint(week: $0.offset, value: $0.element, series: "You") }
    }

    private var benchmarkPoints: [ChartPoint] {
        benchmarkSeries.enumerated().map { ChartPoint(week: $0.offset, value: $0.element, series: "Benchmark") }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Chart {
                // User area + line
                ForEach(userPoints) { point in
                    AreaMark(
                        x: .value("Week", point.week),
                        y: .value(metricName, point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.tiktokAccent.opacity(0.25), Color.tiktokAccent.opacity(0.02)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Week", point.week),
                        y: .value(metricName, point.value)
                    )
                    .foregroundStyle(Color.tiktokAccent)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .interpolationMethod(.catmullRom)
                    .symbol(Circle().strokeBorder(lineWidth: 2))
                    .symbolSize(30)
                }

                // Benchmark line
                if showBenchmark {
                    ForEach(benchmarkPoints) { point in
                        LineMark(
                            x: .value("Week", point.week),
                            y: .value("Benchmark", point.value)
                        )
                        .foregroundStyle(Color.gray.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [5, 4]))
                        .interpolationMethod(.catmullRom)
                    }
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisValueLabel().font(.appCaption2).foregroundStyle(Color.secondary)
                }
            }
            .frame(height: 120)

            // Legend
            HStack(spacing: 16) {
                legendItem(color: .tiktokAccent, dashed: false, label: "Your performance")
                if showBenchmark {
                    legendItem(color: .gray.opacity(0.5), dashed: true, label: "Benchmark avg")
                }
            }
        }
    }

    private func legendItem(color: Color, dashed: Bool, label: String) -> some View {
        HStack(spacing: 5) {
            if dashed {
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle().fill(color).frame(width: 4, height: 2)
                    }
                }
            } else {
                Circle().fill(color).frame(width: 8, height: 8)
            }
            Text(label)
                .font(.appCaption2)
                .foregroundStyle(Color.secondary)
        }
    }
}

struct ChartPoint: Identifiable {
    let id = UUID()
    let week: Int
    let value: Double
    let series: String
}
