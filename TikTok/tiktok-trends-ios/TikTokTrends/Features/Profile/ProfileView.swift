import SwiftUI

struct ProfileView: View {
    @Environment(AuthManager.self) private var auth

    var body: some View {
        ZStack {
            Color.tiktokBackground.ignoresSafeArea()
            VStack(spacing: 24) {
                // Avatar
                Circle()
                    .fill(LinearGradient(colors: [.tiktokPrimary, .tiktokAccent],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(auth.currentUser?.tiktokHandle.prefix(1).uppercased() ?? "?")
                            .font(.appTitle)
                            .foregroundStyle(.white)
                    )

                VStack(spacing: 4) {
                    Text(auth.currentUser?.displayName ?? auth.currentUser?.tiktokHandle ?? "Creator")
                        .font(.appTitle2)
                    Text("@\(auth.currentUser?.tiktokHandle ?? "")")
                        .font(.appSubheadline)
                        .foregroundStyle(Color.secondary)
                    if let niche = auth.currentUser?.niche {
                        PillBadge(text: niche)
                            .padding(.top, 4)
                    }
                }

                Spacer()

                Button("Log Out") { auth.logout() }
                    .buttonStyle(PinkButtonStyle(isDestructive: true))
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
            .padding(.top, 40)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}
