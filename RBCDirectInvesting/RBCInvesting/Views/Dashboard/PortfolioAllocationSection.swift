import SwiftUI
import DGCharts

enum AllocationGrouping: String, CaseIterable {
    case byHolding = "By Holding"
    case bySector = "By Sector"
}

struct PortfolioAllocationSection: View {
    @ObservedObject var portfolioVM: PortfolioViewModel
    @State private var grouping: AllocationGrouping = .byHolding
    @State private var selectedEntry: AllocationEntry?
    @State private var showDetail = false

    private static let sliceColors: [UIColor] = [
        UIColor(Color.rbcBlue),
        UIColor(Color.rbcGold),
        UIColor(Color.gainGreen),
        UIColor.systemTeal,
        UIColor.systemPurple,
        UIColor.systemOrange,
        UIColor.systemPink,
        UIColor.systemIndigo,
        UIColor.systemBrown,
        UIColor.systemCyan,
    ]

    private var entries: [AllocationEntry] {
        guard let holdings = portfolioVM.portfolio?.holdings else { return [] }
        let totalValue = holdings.compactMap(\.marketValue).reduce(0, +)
        guard totalValue > 0 else { return [] }

        switch grouping {
        case .byHolding:
            // Group by symbol, sum market values
            let grouped = Dictionary(grouping: holdings, by: \.symbol)
            return grouped.map { symbol, holdingGroup in
                let value = holdingGroup.compactMap(\.marketValue).reduce(0, +)
                return AllocationEntry(
                    label: symbol,
                    value: value,
                    percentage: (value / totalValue) * 100,
                    holdings: holdingGroup
                )
            }
            .sorted { $0.value > $1.value }

        case .bySector:
            let grouped = Dictionary(grouping: holdings) { SectorMapping.sector(for: $0.symbol) }
            return grouped.map { sector, holdingGroup in
                let value = holdingGroup.compactMap(\.marketValue).reduce(0, +)
                return AllocationEntry(
                    label: sector,
                    value: value,
                    percentage: (value / totalValue) * 100,
                    holdings: holdingGroup
                )
            }
            .sorted { $0.value > $1.value }
        }
    }

    private var pieEntries: [PieChartDataEntry] {
        entries.map { PieChartDataEntry(value: $0.percentage, label: $0.label) }
    }

    private var pieColors: [UIColor] {
        entries.indices.map { Self.sliceColors[$0 % Self.sliceColors.count] }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Portfolio Allocation")
                .font(.title3.bold())

            // Grouping picker
            Picker("", selection: $grouping) {
                ForEach(AllocationGrouping.allCases, id: \.self) {
                    Text($0.rawValue)
                }
            }
            .pickerStyle(.segmented)

            // Pie chart
            if !entries.isEmpty {
                PieChartRepresentable(
                    entries: pieEntries,
                    colors: pieColors,
                    onSliceTapped: { index in
                        if index < entries.count {
                            selectedEntry = entries[index]
                            showDetail = true
                        }
                    }
                )
                .frame(height: 240)

                // Legend
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(Self.sliceColors[index % Self.sliceColors.count]))
                                .frame(width: 10, height: 10)
                            Text(entry.label)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text(String(format: "%.1f%%", entry.percentage))
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        .sheet(isPresented: $showDetail) {
            if let entry = selectedEntry {
                SliceDetailView(entry: entry)
                    .presentationDetents([.medium, .large])
            }
        }
    }
}
