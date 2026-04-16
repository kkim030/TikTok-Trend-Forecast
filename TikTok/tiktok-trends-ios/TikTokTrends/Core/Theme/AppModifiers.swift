import SwiftUI

// MARK: - Card Style

struct PinkCardModifier: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.tiktokPrimary.opacity(0.25), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func pinkCard(padding: CGFloat = 16) -> some View {
        modifier(PinkCardModifier(padding: padding))
    }
}

// MARK: - Button Styles

struct PinkButtonStyle: ButtonStyle {
    var isDestructive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appHeadline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isDestructive ? Color.gradeF : Color.tiktokAccent
            )
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appHeadline)
            .foregroundStyle(Color.tiktokAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.clear)
            .overlay(
                Capsule()
                    .strokeBorder(Color.tiktokAccent, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Shimmer Loading

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: phase - 0.3),
                        .init(color: .white.opacity(0.5), location: phase),
                        .init(color: .clear, location: phase + 0.3)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1.3
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Pill Badge

struct PillBadge: View {
    let text: String
    var color: Color = .tiktokAccent
    var foreground: Color = .white

    var body: some View {
        Text(text)
            .font(.appCaption)
            .fontWeight(.semibold)
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }
}

// MARK: - Trend Type Badge

extension String {
    var trendTypeBadgeColor: Color {
        switch self.lowercased() {
        case "hashtag":          return .tiktokAccent
        case "music":            return .tiktokLavender
        case "content_category": return .tiktokMint
        default:                 return .tiktokPrimary
        }
    }

    var trendTypeIcon: String {
        switch self.lowercased() {
        case "hashtag":          return "number"
        case "music":            return "music.note"
        case "content_category": return "square.grid.2x2.fill"
        default:                 return "chart.line.uptrend.xyaxis"
        }
    }

    var trendTypeLabel: String {
        switch self.lowercased() {
        case "hashtag":          return "Hashtag"
        case "music":            return "Music"
        case "content_category": return "Category"
        default:                 return self.capitalized
        }
    }
}

// MARK: - Velocity Flame

struct VelocityFlame: View {
    let score: Double   // 0–100+

    private var intensity: Int {
        switch score {
        case 80...: return 3
        case 50...: return 2
        case 20...: return 1
        default:    return 0
        }
    }

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<3) { i in
                Image(systemName: "flame.fill")
                    .font(.appCaption2)
                    .foregroundStyle(i < intensity ? Color.orange : Color.gray.opacity(0.3))
            }
        }
    }
}
