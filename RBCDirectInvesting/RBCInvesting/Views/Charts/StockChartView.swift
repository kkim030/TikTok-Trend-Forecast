import SwiftUI
import DGCharts

struct StockChartView: UIViewRepresentable {
    let symbol: String
    let dataPoints: [Double]

    func makeUIView(context: Context) -> LineChartView {
        let chart = LineChartView()
        chart.rightAxis.enabled = false
        chart.leftAxis.drawGridLinesEnabled = true
        chart.leftAxis.gridColor = .systemGray5
        chart.xAxis.drawGridLinesEnabled = false
        chart.xAxis.drawLabelsEnabled = false
        chart.legend.enabled = false
        chart.dragEnabled = true
        chart.setScaleEnabled(false)
        chart.pinchZoomEnabled = false
        chart.animate(xAxisDuration: 0.5)
        chart.noDataText = "Loading chart..."
        return chart
    }

    func updateUIView(_ chart: LineChartView, context: Context) {
        guard !dataPoints.isEmpty else { return }

        let entries = dataPoints.enumerated().map { (i, val) in
            ChartDataEntry(x: Double(i), y: val)
        }

        let dataSet = LineChartDataSet(entries: entries, label: symbol)
        let isPositive = (dataPoints.last ?? 0) >= (dataPoints.first ?? 0)

        dataSet.colors = [isPositive ? .systemGreen : .systemRed]
        dataSet.drawCirclesEnabled = false
        dataSet.lineWidth = 2
        dataSet.mode = .cubicBezier
        dataSet.drawFilledEnabled = true
        dataSet.fillColor = isPositive ? .systemGreen : .systemRed
        dataSet.fillAlpha = 0.1
        dataSet.drawValuesEnabled = false
        dataSet.highlightColor = .systemBlue
        dataSet.highlightLineWidth = 1

        chart.data = LineChartData(dataSet: dataSet)
    }
}

struct StockDetailView: View {
    let symbol: String
    @State private var quote: Quote?
    @State private var chartData: [Double] = []
    @State private var selectedRange = "1M"

    let ranges = ["1D", "5D", "1M", "3M", "1Y"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Price header
                if let q = quote {
                    VStack(spacing: 4) {
                        Text(q.currentPrice.currencyFormatted)
                            .font(.system(size: 36, weight: .bold))
                        HStack(spacing: 8) {
                            GainLossText(value: q.change, fontSize: .title3)
                            GainLossPercentBadge(percent: q.changePercent)
                        }
                    }
                    .padding(.top)
                }

                // Chart
                StockChartView(symbol: symbol, dataPoints: chartData)
                    .frame(height: 250)
                    .padding(.horizontal)

                // Range selector
                HStack {
                    ForEach(ranges, id: \.self) { range in
                        Button(range) {
                            selectedRange = range
                            generateChartData()
                        }
                        .font(.caption.bold())
                        .foregroundColor(selectedRange == range ? .white : .rbcBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedRange == range ? Color.rbcBlue : Color.clear)
                        .cornerRadius(14)
                    }
                }

                // Quote details
                if let q = quote {
                    VStack(spacing: 0) {
                        QuoteDetailRow(label: "Open", value: q.open.currencyFormatted)
                        Divider()
                        QuoteDetailRow(label: "High", value: q.high.currencyFormatted)
                        Divider()
                        QuoteDetailRow(label: "Low", value: q.low.currencyFormatted)
                        Divider()
                        QuoteDetailRow(label: "Prev Close", value: q.previousClose.currencyFormatted)
                        Divider()
                        QuoteDetailRow(label: "Volume", value: q.volume != nil ? "\(q.volume!)" : "N/A")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle(symbol)
        .task {
            do {
                quote = try await APIService.shared.get("/quotes/\(symbol)")
                generateChartData()
            } catch {}
        }
    }

    private func generateChartData() {
        guard let q = quote else { return }
        let count: Int
        switch selectedRange {
        case "1D": count = 78
        case "5D": count = 390
        case "1M": count = 22
        case "3M": count = 66
        case "1Y": count = 252
        default: count = 22
        }
        // Generate simulated price data based on current quote
        var data: [Double] = []
        var price = q.previousClose
        for _ in 0..<count {
            let change = Double.random(in: -0.02...0.02) * price
            price += change
            data.append(price)
        }
        // Ensure last point matches current price
        if !data.isEmpty {
            data[data.count - 1] = q.currentPrice
        }
        chartData = data
    }
}

struct QuoteDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .padding(.vertical, 8)
    }
}
