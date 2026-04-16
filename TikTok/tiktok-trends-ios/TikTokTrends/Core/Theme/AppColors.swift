import SwiftUI

extension Color {
    // MARK: - Kawaii Bento Palette
    static let tiktokBackground  = Color(hex: "#FFF0F3")  // soft pink bg
    static let tiktokPrimary     = Color(hex: "#FFB6C1")  // light pink
    static let tiktokAccent      = Color(hex: "#E91E8C")  // hot pink CTAs
    static let tiktokDarkAccent  = Color(hex: "#C2185B")  // pressed / text
    static let tiktokMint        = Color(hex: "#B2DFDB")  // success / grade A
    static let tiktokLavender    = Color(hex: "#E1BEE7")  // draft / secondary

    // MARK: - Grade Colors
    static let gradeA = Color(hex: "#4CAF50")   // green
    static let gradeB = Color(hex: "#2196F3")   // blue
    static let gradeC = Color(hex: "#FFC107")   // amber
    static let gradeD = Color(hex: "#FF9800")   // orange
    static let gradeF = Color(hex: "#F44336")   // red

    // MARK: - Hex initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    static func gradeColor(for grade: String) -> Color {
        switch grade.uppercased() {
        case "A": return .gradeA
        case "B": return .gradeB
        case "C": return .gradeC
        case "D": return .gradeD
        default:  return .gradeF
        }
    }

    // MARK: - iOS 17 polyfill for Color.mix (which is iOS 18+)
    func mix(with color: Color, by amount: Double) -> Color {
        let a = UIColor(self)
        let b = UIColor(color)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let t = CGFloat(amount)
        return Color(
            red:   Double(r1 + (r2 - r1) * t),
            green: Double(g1 + (g2 - g1) * t),
            blue:  Double(b1 + (b2 - b1) * t)
        )
    }
}
