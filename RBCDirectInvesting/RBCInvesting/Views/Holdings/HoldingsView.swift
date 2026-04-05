import SwiftUI

struct HoldingsView: View {
    @StateObject private var portfolioVM = PortfolioViewModel()
    @State private var selectedAccount: UUID?
    @State private var sortBy: SortOption = .marketValue
    var preselectedAccountId: UUID? = nil

    enum SortOption: String, CaseIterable {
        case symbol = "Symbol"
        case marketValue = "Market Value"
        case gainLoss = "Gain/Loss"
        case dayChange = "Day Change"
    }

    var filteredHoldings: [Holding] {
        let holdings = portfolioVM.portfolio?.holdings ?? []
        let filtered = selectedAccount == nil ? holdings : holdings.filter { $0.accountId == selectedAccount }
        return filtered.sorted { a, b in
            switch sortBy {
            case .symbol: return a.symbol < b.symbol
            case .marketValue: return (a.marketValue ?? 0) > (b.marketValue ?? 0)
            case .gainLoss: return (a.gainLossPercent ?? 0) > (b.gainLossPercent ?? 0)
            case .dayChange: return (a.dayChangePercent ?? 0) > (b.dayChangePercent ?? 0)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
                // Account filter
                if let accounts = portfolioVM.portfolio?.accounts, !accounts.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "All", isSelected: selectedAccount == nil) {
                                selectedAccount = nil
                            }
                            ForEach(accounts) { acc in
                                FilterChip(label: acc.accountType.displayName, isSelected: selectedAccount == acc.id) {
                                    selectedAccount = acc.id
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .background(Color(.systemGray6))
                }

                // Sort picker
                HStack {
                    Text("\(filteredHoldings.count) holdings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Picker("Sort", selection: $sortBy) {
                        ForEach(SortOption.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Holdings list
                List(filteredHoldings) { holding in
                    HoldingRow(holding: holding)
                }
                .listStyle(.plain)
            }
        .navigationTitle("Holdings")
        .refreshable {
            await portfolioVM.loadPortfolio()
        }
        .task {
            await portfolioVM.loadPortfolio()
            if let preselected = preselectedAccountId {
                selectedAccount = preselected
            }
        }
    }
}

struct HoldingRow: View {
    let holding: Holding

    var body: some View {
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
                InfoCell(label: "Qty", value: String(format: "%.0f", holding.quantity))
                InfoCell(label: "Avg Cost", value: holding.avgCost.currencyFormatted)
                InfoCell(label: "Mkt Value", value: (holding.marketValue ?? 0).currencyFormatted)
                InfoCell(label: "G/L", value: (holding.gainLoss ?? 0).changeFormatted,
                         color: (holding.gainLoss ?? 0) >= 0 ? .gainGreen : .lossRed)
            }
        }
        .padding(.vertical, 4)
    }
}

struct InfoCell: View {
    let label: String
    let value: String
    var color: Color = .primary

    var body: some View {
        VStack(spacing: 2) {
            Text(label).font(.caption2).foregroundColor(.secondary)
            Text(value).font(.caption.bold()).foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.bold())
                .foregroundColor(isSelected ? .white : .rbcBlue)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.rbcBlue : Color.clear)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.rbcBlue, lineWidth: 1))
        }
    }
}
