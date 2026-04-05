import SwiftUI
import DGCharts

struct PieChartRepresentable: UIViewRepresentable {
    let entries: [PieChartDataEntry]
    let colors: [UIColor]
    var onSliceTapped: ((Int) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(onSliceTapped: onSliceTapped)
    }

    func makeUIView(context: Context) -> PieChartView {
        let chart = PieChartView()
        chart.delegate = context.coordinator
        chart.legend.enabled = false
        chart.drawEntryLabelsEnabled = true
        chart.entryLabelColor = .label
        chart.entryLabelFont = .systemFont(ofSize: 11)
        chart.holeRadiusPercent = 0.45
        chart.transparentCircleRadiusPercent = 0.48
        chart.holeColor = .systemBackground
        chart.rotationEnabled = false
        chart.highlightPerTapEnabled = true
        chart.animate(xAxisDuration: 0.6)
        chart.noDataText = "No allocation data"
        return chart
    }

    func updateUIView(_ chart: PieChartView, context: Context) {
        guard !entries.isEmpty else {
            chart.data = nil
            return
        }

        context.coordinator.onSliceTapped = onSliceTapped

        let dataSet = PieChartDataSet(entries: entries, label: "")
        dataSet.colors = colors
        dataSet.drawValuesEnabled = true
        dataSet.valueFormatter = PercentValueFormatter()
        dataSet.valueFont = .systemFont(ofSize: 10, weight: .medium)
        dataSet.valueTextColor = .label
        dataSet.sliceSpace = 2
        dataSet.selectionShift = 6

        chart.data = PieChartData(dataSet: dataSet)
    }

    class Coordinator: NSObject, ChartViewDelegate {
        var onSliceTapped: ((Int) -> Void)?

        init(onSliceTapped: ((Int) -> Void)?) {
            self.onSliceTapped = onSliceTapped
        }

        func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
            let index = Int(highlight.x)
            onSliceTapped?(index)
        }
    }
}

class PercentValueFormatter: ValueFormatter {
    func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
        if value < 5 { return "" } // Hide labels for small slices
        return String(format: "%.0f%%", value)
    }
}
