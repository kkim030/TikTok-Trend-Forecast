import SwiftUI

struct AutoInvestView: View {
    @StateObject private var autoInvestVM = AutoInvestViewModel()
    @State private var showSetupSheet = false

    var body: some View {
        Group {
            if autoInvestVM.rules.isEmpty {
                VStack(spacing: 20) {
                    Spacer()

                    Image(systemName: "repeat.circle")
                        .font(.system(size: 56))
                        .foregroundColor(.rbcBlue.opacity(0.4))

                    Text("No Auto-Invest Rules")
                        .font(.title3.bold())

                    Text("Set up recurring investments to automatically buy securities on a schedule.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Button("Set Up Auto-Investing") {
                        showSetupSheet = true
                    }
                    .buttonStyle(RBCButtonStyle())
                    .padding(.horizontal, 40)

                    Spacer()
                }
            } else {
                List {
                    Section("Active Rules") {
                        ForEach(autoInvestVM.rules.filter { $0.isActive }) { rule in
                            AutoInvestRuleRow(
                                rule: rule,
                                accounts: autoInvestVM.accounts,
                                onToggle: { autoInvestVM.toggleRule(id: rule.id) }
                            )
                        }
                        .onDelete { indexSet in
                            let activeRules = autoInvestVM.rules.filter { $0.isActive }
                            for idx in indexSet {
                                autoInvestVM.deleteRule(id: activeRules[idx].id)
                            }
                        }
                    }

                    let pausedRules = autoInvestVM.rules.filter { !$0.isActive }
                    if !pausedRules.isEmpty {
                        Section("Paused") {
                            ForEach(pausedRules) { rule in
                                AutoInvestRuleRow(
                                    rule: rule,
                                    accounts: autoInvestVM.accounts,
                                    onToggle: { autoInvestVM.toggleRule(id: rule.id) }
                                )
                            }
                            .onDelete { indexSet in
                                for idx in indexSet {
                                    autoInvestVM.deleteRule(id: pausedRules[idx].id)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Auto-Investing")
        .toolbar {
            if !autoInvestVM.rules.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSetupSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
        }
        .sheet(isPresented: $showSetupSheet) {
            AutoInvestSetupSheet(autoInvestVM: autoInvestVM)
        }
        .task {
            autoInvestVM.loadRules()
            await autoInvestVM.loadAccounts()
        }
    }
}
