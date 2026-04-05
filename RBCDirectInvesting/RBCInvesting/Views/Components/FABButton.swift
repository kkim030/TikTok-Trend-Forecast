import SwiftUI

struct FABButton: View {
    @Binding var isExpanded: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.rbcFABYellow)
                    .frame(width: 56, height: 56)
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

                Image(systemName: isExpanded ? "xmark" : "chevron.up")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                    .rotationEffect(.degrees(isExpanded ? 0 : 0))
            }
        }
    }
}
