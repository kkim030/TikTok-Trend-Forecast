import SwiftUI

extension Color {
    // RBC brand colors
    static let rbcBlue = Color(red: 0, green: 0.365, blue: 0.667)      // #005DAA
    static let rbcGold = Color(red: 1, green: 0.824, blue: 0)           // #FFD200
    static let rbcDarkBlue = Color(red: 0, green: 0.204, blue: 0.412)   // #003469
    static let rbcLightBlue = Color(red: 0.9, green: 0.95, blue: 1.0)
    static let rbcFABYellow = Color(red: 1.0, green: 0.80, blue: 0.0)
    static let rbcOrangeAccent = Color(red: 0.89, green: 0.58, blue: 0.08)
    static let rbcScreenBackground = Color(UIColor.systemGroupedBackground)

    static let gainGreen = Color(red: 0.18, green: 0.49, blue: 0.2)
    static let lossRed = Color(red: 0.83, green: 0.18, blue: 0.18)
}

extension Double {
    var currencyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CAD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }

    var percentFormatted: String {
        String(format: "%+.2f%%", self)
    }

    var changeFormatted: String {
        String(format: "%+.2f", self)
    }
}

// MARK: - Reusable Components

struct RBCCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}

extension View {
    func rbcCard() -> some View {
        modifier(RBCCardModifier())
    }
}

struct RBCOutlinedCircleIcon: View {
    let systemName: String
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.rbcBlue.opacity(0.3), lineWidth: 1.5)
                .frame(width: size, height: size)
            Image(systemName: systemName)
                .font(.system(size: size * 0.4))
                .foregroundColor(.rbcBlue)
        }
    }
}

struct RBCMenuRow: View {
    let icon: String
    let label: String
    var showChevron: Bool = true

    var body: some View {
        HStack(spacing: 16) {
            RBCOutlinedCircleIcon(systemName: icon)
            Text(label)
                .font(.body)
                .foregroundColor(.primary)
            Spacer()
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

struct RBCButtonStyle: ButtonStyle {
    var isPrimary: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(isPrimary ? .white : .rbcBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isPrimary ? Color.rbcBlue : Color.clear)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.rbcBlue, lineWidth: isPrimary ? 0 : 2)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
