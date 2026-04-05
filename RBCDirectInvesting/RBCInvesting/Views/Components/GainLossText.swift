import SwiftUI

struct GainLossText: View {
    let value: Double
    var showSign: Bool = true
    var fontSize: Font = .body

    var body: some View {
        Text(showSign ? value.changeFormatted : String(format: "%.2f", value))
            .font(fontSize)
            .foregroundColor(value >= 0 ? .gainGreen : .lossRed)
    }
}

struct GainLossPercentBadge: View {
    let percent: Double

    var body: some View {
        Text(percent.percentFormatted)
            .font(.caption.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(percent >= 0 ? Color.gainGreen : Color.lossRed)
            .cornerRadius(6)
    }
}
