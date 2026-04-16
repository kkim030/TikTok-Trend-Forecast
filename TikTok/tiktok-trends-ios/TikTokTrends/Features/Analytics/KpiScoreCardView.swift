import SwiftUI

struct KpiScoreCardView: View {
    let metric: KpiMetric
    let grade: String
    let value: String
    var isSelected: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Grade letter
                Text(grade)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(Color.gradeColor(for: grade))

                // Metric name
                Text(metric.rawValue)
                    .font(.appCaption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Numeric value
                Text(value)
                    .font(.appCaption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 14)
            .frame(width: 100)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.tiktokPrimary.opacity(isSelected ? 0 : 0.2),
                    radius: 10, x: 0, y: 3)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isSelected ? Color.tiktokAccent : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.04 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(IconButtonStyle())
    }
}
