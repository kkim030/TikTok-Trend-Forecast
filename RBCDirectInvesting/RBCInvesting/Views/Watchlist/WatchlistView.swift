import SwiftUI

struct WatchlistView: View {
    @StateObject private var watchlistVM = WatchlistViewModel()
    @State private var showAddWatchlist = false
    @State private var newWatchlistName = ""
    @State private var showAddSymbol = false
    @State private var addToWatchlistId: UUID?
    @State private var newSymbol = ""

    var body: some View {
        Group {
                if watchlistVM.isLoading && watchlistVM.watchlists.isEmpty {
                    ProgressView().padding(.top, 40)
                } else if watchlistVM.watchlists.isEmpty {
                    ContentUnavailableView("No Watchlists",
                        systemImage: "star",
                        description: Text("Create a watchlist to track stocks"))
                } else {
                    List {
                        ForEach(watchlistVM.watchlists) { wl in
                            Section(header: HStack {
                                Text(wl.name)
                                Spacer()
                                Button {
                                    addToWatchlistId = wl.id
                                    showAddSymbol = true
                                } label: {
                                    Image(systemName: "plus.circle")
                                }
                            }) {
                                if let items = wl.items, !items.isEmpty {
                                    ForEach(items) { item in
                                        WatchlistItemRow(
                                            item: item,
                                            quote: watchlistVM.quotes[item.symbol]
                                        )
                                        .swipeActions(edge: .trailing) {
                                            Button("Delete", role: .destructive) {
                                                Task { await watchlistVM.removeItem(watchlistId: wl.id, itemId: item.id) }
                                            }
                                        }
                                    }
                                } else {
                                    Text("No symbols added yet")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            for idx in indexSet {
                                let wl = watchlistVM.watchlists[idx]
                                Task { await watchlistVM.deleteWatchlist(wl.id) }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Watchlist")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddWatchlist = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                    }
                }
            }
            .alert("New Watchlist", isPresented: $showAddWatchlist) {
                TextField("Name", text: $newWatchlistName)
                Button("Create") {
                    Task { await watchlistVM.createWatchlist(name: newWatchlistName) }
                    newWatchlistName = ""
                }
                Button("Cancel", role: .cancel) { newWatchlistName = "" }
            }
            .alert("Add Symbol", isPresented: $showAddSymbol) {
                TextField("Symbol (e.g. AAPL)", text: $newSymbol)
                    .autocapitalization(.allCharacters)
                Button("Add") {
                    if let wlId = addToWatchlistId {
                        Task { await watchlistVM.addItem(watchlistId: wlId, symbol: newSymbol.uppercased()) }
                    }
                    newSymbol = ""
                }
                Button("Cancel", role: .cancel) { newSymbol = "" }
            }
        .refreshable { await watchlistVM.loadWatchlists() }
        .task { await watchlistVM.loadWatchlists() }
    }
}

struct WatchlistItemRow: View {
    let item: WatchlistItemResponse
    let quote: Quote?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.symbol).font(.headline)
                Text(item.exchange).font(.caption).foregroundColor(.secondary)
            }

            Spacer()

            if let q = quote {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(q.currentPrice.currencyFormatted).font(.subheadline)
                    HStack(spacing: 4) {
                        GainLossText(value: q.change, fontSize: .caption)
                        GainLossPercentBadge(percent: q.changePercent)
                    }
                }
            } else {
                ProgressView()
            }
        }
    }
}
