import SwiftUI

struct OrderEntryView: View {
    @StateObject private var orderVM = OrderViewModel()
    @State private var showOrderForm = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Recent orders
                if orderVM.isLoading && orderVM.orders.isEmpty {
                    ProgressView().padding(.top, 40)
                } else if orderVM.orders.isEmpty {
                    ContentUnavailableView("No Orders Yet",
                        systemImage: "doc.text",
                        description: Text("Tap + to place your first trade"))
                } else {
                    List(orderVM.orders) { order in
                        OrderRow(order: order, onCancel: {
                            Task { await orderVM.cancelOrder(order.id) }
                        })
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Trade")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showOrderForm = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showOrderForm) {
                OrderFormSheet(orderVM: orderVM)
            }
            .refreshable { await orderVM.loadOrders() }
            .task {
                await orderVM.loadAccounts()
                await orderVM.loadOrders()
            }
        }
    }
}

struct OrderRow: View {
    let order: OrderResponse
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(order.side.rawValue)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(order.side == .BUY || order.side == .COVER ? Color.gainGreen : Color.lossRed)
                    .cornerRadius(4)

                Text(order.symbol)
                    .font(.headline)

                Text(order.exchange)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(order.status.rawValue)
                    .font(.caption.bold())
                    .foregroundColor(statusColor(order.status))
            }

            HStack {
                InfoCell(label: "Type", value: order.orderType.displayName)
                InfoCell(label: "Qty", value: String(format: "%.0f", order.quantity))
                InfoCell(label: "Price", value: order.limitPrice != nil ? order.limitPrice!.currencyFormatted : "Market")
                InfoCell(label: "Commission", value: (order.commission ?? 9.95).currencyFormatted)
            }

            if order.status == .PENDING {
                Button("Cancel Order") { onCancel() }
                    .font(.caption.bold())
                    .foregroundColor(.lossRed)
            }
        }
        .padding(.vertical, 4)
    }

    func statusColor(_ status: OrderStatus) -> Color {
        switch status {
        case .FILLED: return .gainGreen
        case .PENDING, .PARTIAL: return .orange
        case .CANCELLED, .REJECTED: return .lossRed
        }
    }
}

struct OrderFormSheet: View {
    @ObservedObject var orderVM: OrderViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedAccountId: UUID?
    @State private var symbol = ""
    @State private var side: OrderSide = .BUY
    @State private var orderType: OrderType = .MARKET
    @State private var quantity = ""
    @State private var limitPrice = ""
    @State private var duration: OrderDuration = .DAY
    @State private var showConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    Picker("Account", selection: $selectedAccountId) {
                        Text("Select account").tag(nil as UUID?)
                        ForEach(orderVM.accounts) { acc in
                            Text("\(acc.accountType.displayName) — \(acc.accountNumber)")
                                .tag(acc.id as UUID?)
                        }
                    }
                }

                Section("Symbol") {
                    TextField("Enter symbol (e.g. RY)", text: $symbol)
                        .autocapitalization(.allCharacters)
                        .onChange(of: symbol) { _, newVal in
                            if newVal.count >= 2 {
                                Task { await orderVM.fetchQuote(symbol: newVal) }
                            }
                        }

                    if let q = orderVM.quote {
                        HStack {
                            Text(q.symbol).font(.headline)
                            Spacer()
                            Text(q.currentPrice.currencyFormatted).font(.headline)
                            GainLossPercentBadge(percent: q.changePercent)
                        }
                    }
                }

                Section("Order Details") {
                    Picker("Action", selection: $side) {
                        ForEach(OrderSide.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    .pickerStyle(.segmented)

                    Picker("Order Type", selection: $orderType) {
                        ForEach(OrderType.allCases, id: \.self) { Text($0.displayName) }
                    }

                    TextField("Quantity", text: $quantity)
                        .keyboardType(.numberPad)

                    if orderType == .LIMIT || orderType == .STOP_LIMIT {
                        TextField("Limit Price", text: $limitPrice)
                            .keyboardType(.decimalPad)
                    }

                    Picker("Duration", selection: $duration) {
                        ForEach(OrderDuration.allCases, id: \.self) { Text($0.displayName) }
                    }
                }

                // Estimated cost
                if let qty = Double(quantity), let q = orderVM.quote {
                    let price = orderType == .MARKET ? q.currentPrice : (Double(limitPrice) ?? q.currentPrice)
                    let total = qty * price + 9.95
                    Section("Estimate") {
                        HStack { Text("Shares"); Spacer(); Text("\(Int(qty))") }
                        HStack { Text("Price"); Spacer(); Text(price.currencyFormatted) }
                        HStack { Text("Commission"); Spacer(); Text("$9.95") }
                        HStack {
                            Text("Estimated Total").bold()
                            Spacer()
                            Text(total.currencyFormatted).bold()
                        }
                    }
                }

                if let error = orderVM.errorMessage {
                    Section { Text(error).foregroundColor(.red) }
                }

                if let success = orderVM.successMessage {
                    Section { Text(success).foregroundColor(.green) }
                }

                Section {
                    Button("Review Order") { showConfirm = true }
                        .buttonStyle(RBCButtonStyle())
                        .disabled(selectedAccountId == nil || symbol.isEmpty || quantity.isEmpty)
                }
            }
            .navigationTitle("New Order")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Confirm Order", isPresented: $showConfirm) {
                Button("Submit") {
                    Task {
                        let req = OrderRequest(
                            accountId: selectedAccountId!,
                            symbol: symbol.uppercased(),
                            side: side,
                            orderType: orderType,
                            quantity: Double(quantity) ?? 0,
                            limitPrice: Double(limitPrice),
                            duration: duration
                        )
                        await orderVM.submitOrder(req)
                        if orderVM.errorMessage == nil { dismiss() }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("\(side.rawValue) \(quantity) \(symbol.uppercased()) at \(orderType == .MARKET ? "Market" : limitPrice)")
            }
        }
    }
}
