import SwiftUI

struct SliceDetailView: View {
    let entry: AllocationEntry

    var body: some View {
        NavigationStack {
            List {
                // Header
                Section {
                    VStack(alignment: .center, spacing: 8) {
                        Text(entry.label)
                            .font(.title2.bold())
                        Text(String(format: "%.1f%% of portfolio", entry.percentage))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(entry.value.currencyFormatted)
                            .font(.title3.bold())
                            .foregroundColor(.rbcBlue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                // Holdings in this slice
                Section("Holdings") {
                    ForEach(entry.holdings) { holding in
                        VStack(spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(holding.symbol)
                                        .font(.headline)
                                    Text(holding.exchange)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text((holding.currentPrice ?? 0).currencyFormatted)
                                        .font(.subheadline)
                                    if let dc = holding.dayChangePercent {
                                        GainLossPercentBadge(percent: dc)
                                    }
                                }
                            }

                            HStack {
                                InfoCell(label: "Book Cost", value: holding.bookValue.currencyFormatted)
                                InfoCell(label: "Mkt Value", value: (holding.marketValue ?? 0).currencyFormatted)
                                InfoCell(
                                    label: "Gain/Loss",
                                    value: (holding.gainLoss ?? 0).changeFormatted,
                                    color: (holding.gainLoss ?? 0) >= 0 ? .gainGreen : .lossRed
                                )
                            }

                            // Mini sparkline
                            SparklineView(
                                data: generateSparkline(for: holding),
                                isPositive: (holding.dayChange ?? 0) >= 0
                            )
                            .frame(height: 40)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Allocation Detail")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func generateSparkline(for holding: Holding) -> [Double] {
        guard let price = holding.currentPrice else { return [] }
        let prevClose = price - (holding.dayChange ?? 0)
        var points: [Double] = []
        var p = prevClose
        for _ in 0..<10 {
            let change = Double.random(in: -0.01...0.01) * p
            p += change
            points.append(p)
        }
        points.append(price)
        return points
    }
}
