import SwiftUI

struct LoginView: View {
    @State private var vm = LoginViewModel()

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color.tiktokBackground, Color.tiktokPrimary],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo + title
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 100, height: 100)
                            .shadow(color: Color.tiktokAccent.opacity(0.2), radius: 20, x: 0, y: 8)

                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(Color.tiktokAccent)
                    }

                    Text("TikTok Trends")
                        .font(.appLargeTitle)
                        .foregroundStyle(Color.tiktokDarkAccent)

                    Text("Your AI-powered content companion")
                        .font(.appSubheadline)
                        .foregroundStyle(Color.tiktokDarkAccent.opacity(0.7))
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Auth buttons
                VStack(spacing: 12) {
                    Button {
                        Task { await vm.connectWithTikTok() }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "music.note.tv.fill")
                            Text("Connect with TikTok")
                        }
                    }
                    .buttonStyle(PinkButtonStyle())
                    .disabled(vm.isLoading)

                    Button {
                        Task { await vm.demoLogin() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.circle.fill")
                            Text("Try Demo")
                        }
                    }
                    .buttonStyle(GhostButtonStyle())
                    .disabled(vm.isLoading)
                }
                .padding(.horizontal, 32)

                if let error = vm.errorMessage {
                    Text(error)
                        .font(.appCaption)
                        .foregroundStyle(Color.gradeF)
                        .multilineTextAlignment(.center)
                        .padding(.top, 12)
                        .padding(.horizontal, 32)
                }

                // Loading indicator
                if vm.isLoading {
                    ProgressView()
                        .tint(Color.tiktokAccent)
                        .padding(.top, 16)
                }

                Spacer().frame(height: 48)

                // Privacy note
                Text("By continuing, you agree to our Terms & Privacy Policy")
                    .font(.appCaption2)
                    .foregroundStyle(Color.tiktokDarkAccent.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
        }
        .overlay {
            if vm.isLoading {
                Color.black.opacity(0.1).ignoresSafeArea()
            }
        }
    }
}

#Preview {
    LoginView()
}
