import SwiftUI

struct MoreView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showOrderForm = false
    @State private var navigateToOrderStatus = false
    @State private var navigateToActivity = false
    @State private var navigateToWatchlists = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("More")
                            .font(.largeTitle.bold())

                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.subheadline)
                                .foregroundColor(.rbcBlue)
                            Text("RBC Direct Investing")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Help and Sign Out
                    HStack(spacing: 40) {
                        Spacer()
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .stroke(Color.rbcBlue, lineWidth: 2)
                                    .frame(width: 52, height: 52)
                                Image(systemName: "questionmark")
                                    .font(.title2)
                                    .foregroundColor(.rbcBlue)
                            }
                            Text("Help")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }

                        VStack(spacing: 8) {
                            Button {
                                authVM.logout()
                            } label: {
                                VStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .stroke(Color.rbcBlue, lineWidth: 2)
                                            .frame(width: 52, height: 52)
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .font(.title2)
                                            .foregroundColor(.rbcBlue)
                                    }
                                    Text("Sign Out")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)

                    Divider()
                        .padding(.horizontal, 16)

                    // Direct Investing section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Direct Investing")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)

                        VStack(spacing: 0) {
                            Button { showOrderForm = true } label: {
                                RBCMenuRow(icon: "arrow.left.arrow.right", label: "Place Order")
                                    .padding(.horizontal, 20)
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.leading, 76)

                            NavigationLink(destination: OrderStatusListView()) {
                                RBCMenuRow(icon: "list.bullet.clipboard", label: "View Order Status")
                                    .padding(.horizontal, 20)
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.leading, 76)

                            NavigationLink(destination: TransactionsView()) {
                                RBCMenuRow(icon: "chart.bar.doc.horizontal", label: "View Activity")
                                    .padding(.horizontal, 20)
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.leading, 76)

                            NavigationLink(destination: WatchlistView()) {
                                RBCMenuRow(icon: "star", label: "View Watchlists")
                                    .padding(.horizontal, 20)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                    }

                    // Products section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Products")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)

                        VStack(spacing: 0) {
                            Button {} label: {
                                RBCMenuRow(icon: "doc.badge.plus", label: "Open an Account")
                                    .padding(.horizontal, 20)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color.rbcScreenBackground)
            .sheet(isPresented: $showOrderForm) {
                OrderFormSheet(orderVM: OrderViewModel())
            }
        }
    }
}

// Order status list (extracted from OrderEntryView)
struct OrderStatusListView: View {
    @StateObject private var orderVM = OrderViewModel()

    var body: some View {
        Group {
            if orderVM.isLoading && orderVM.orders.isEmpty {
                ProgressView().padding(.top, 40)
            } else if orderVM.orders.isEmpty {
                ContentUnavailableView("No Orders",
                    systemImage: "doc.text",
                    description: Text("You have no orders yet"))
            } else {
                List(orderVM.orders) { order in
                    OrderRow(order: order, onCancel: {
                        Task { await orderVM.cancelOrder(order.id) }
                    })
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Order Status")
        .refreshable { await orderVM.loadOrders() }
        .task {
            await orderVM.loadAccounts()
            await orderVM.loadOrders()
        }
    }
}
