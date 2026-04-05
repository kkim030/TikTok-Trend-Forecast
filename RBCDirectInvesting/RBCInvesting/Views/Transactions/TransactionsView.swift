import SwiftUI

struct TransactionsView: View {
    @StateObject private var txVM = TransactionViewModel()

    var body: some View {
        List {
            ForEach(txVM.transactions) { tx in
                TransactionRow(transaction: tx)
            }

            if txVM.hasMore {
                ProgressView()
                    .task { await txVM.loadTransactions() }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Transactions")
        .refreshable { await txVM.loadTransactions(reset: true) }
        .task { await txVM.loadTransactions(reset: true) }
    }
}
