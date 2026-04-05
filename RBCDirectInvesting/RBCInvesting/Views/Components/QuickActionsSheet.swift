import SwiftUI

struct QuickActionsSheet: View {
    @Binding var isPresented: Bool
    var onAction: (QuickAction) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        isPresented = false
                    }
                }

            // Action sheet
            VStack(spacing: 0) {
                ForEach(QuickAction.allCases, id: \.displayName) { action in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            isPresented = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onAction(action)
                        }
                    } label: {
                        RBCMenuRow(icon: action.icon, label: action.displayName)
                            .padding(.horizontal, 20)
                    }
                    .buttonStyle(.plain)

                    if action != QuickAction.allCases.last {
                        Divider()
                            .padding(.leading, 72)
                    }
                }
            }
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .padding(.bottom, 80) // space for tab bar
            .transition(.move(edge: .bottom))
        }
    }
}

// Helper for rounding specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
