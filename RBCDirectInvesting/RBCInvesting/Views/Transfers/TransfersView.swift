import SwiftUI

struct TransfersView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Title with orange accent
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Transfers")
                            .font(.largeTitle.bold())
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.rbcOrangeAccent)
                            .frame(width: 50, height: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Move Money section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Move Money")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)

                        VStack(spacing: 0) {
                            TransferMenuRow(icon: "arrow.down", label: "Deposit")
                            Divider().padding(.leading, 60)
                            TransferMenuRow(icon: "arrow.up", label: "Withdraw")
                            Divider().padding(.leading, 60)
                            TransferMenuRow(icon: "arrow.left.arrow.right", label: "Transfer between accounts")
                            Divider().padding(.leading, 60)
                            TransferMenuRow(icon: "coloncurrencysign.arrow.trianglehead.counterclockwise.rotate.90", label: "Foreign exchange (FX) conversion")
                        }
                        .padding(.vertical, 4)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                    }

                    // Auto-Investing section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Auto-Investing")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)

                        VStack(spacing: 0) {
                            NavigationLink(destination: AutoInvestView()) {
                                HStack(spacing: 16) {
                                    Image(systemName: "repeat")
                                        .font(.system(size: 20))
                                        .foregroundColor(.rbcBlue)
                                        .frame(width: 24)
                                    Text("Set up Auto-Investing")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)

                            Divider().padding(.leading, 60)

                            NavigationLink(destination: AutoInvestView()) {
                                HStack(spacing: 16) {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.system(size: 20))
                                        .foregroundColor(.rbcBlue)
                                        .frame(width: 24)
                                    Text("Auto transfer schedule")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                    }

                    // External transfers section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("External transfers")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)

                        VStack(spacing: 0) {
                            TransferMenuRow(icon: "building.columns", label: "Transfer assets or an account")
                        }
                        .padding(.vertical, 4)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                    }

                    // Important Information
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.subheadline)
                        Text("Important Information")
                            .font(.subheadline)
                    }
                    .foregroundColor(.rbcBlue)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                .padding(.bottom, 20)
            }
            .background(Color.rbcScreenBackground)
        }
    }
}

struct TransferMenuRow: View {
    let icon: String
    let label: String

    var body: some View {
        Button {} label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.rbcBlue)
                    .frame(width: 24)
                Text(label)
                    .font(.body)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}
