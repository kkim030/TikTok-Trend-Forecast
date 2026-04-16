import SwiftUI

struct CreateView: View {
    @State private var vm = CreateViewModel()
    @State private var sparkleRotation: Double = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tiktokBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        generateButton
                        if vm.isGenerating { generatingCard }
                        if let error = vm.errorMessage {
                            Text(error).font(.appCaption).foregroundStyle(Color.gradeF)
                                .padding(.horizontal, 16)
                        }
                        recsList
                    }
                    .padding(16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Create ✨")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { AvatarButton() }
            }
            .task { await vm.load() }
        }
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                sparkleRotation = 360
            }
            Task {
                await vm.generate()
                sparkleRotation = 0
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Generate New Idea ✨")
                        .font(.appTitle3).fontWeight(.black).foregroundStyle(.white)
                    Text("Based on today's top trends")
                        .font(.appCaption).foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(sparkleRotation))
            }
            .padding(20)
            .background(
                LinearGradient(colors: [.tiktokAccent, .tiktokDarkAccent],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.tiktokAccent.opacity(0.45), radius: 16, x: 0, y: 8)
        }
        .disabled(vm.isGenerating)
        .scaleEffect(vm.isGenerating ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: vm.isGenerating)
    }

    // MARK: - Generating shimmer card

    private var generatingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ProgressView().tint(Color.tiktokAccent)
                Text("Claude is thinking...")
                    .font(.appSubheadline).fontWeight(.bold).foregroundStyle(Color.tiktokDarkAccent)
            }
            ForEach([0.8, 0.6, 0.9, 0.5], id: \.self) { w in
                RoundedRectangle(cornerRadius: 6).fill(Color.tiktokBackground)
                    .frame(maxWidth: .infinity).frame(height: 10)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6).fill(Color.tiktokPrimary.opacity(0.5))
                            .frame(width: UIScreen.main.bounds.width * 0.7 * w, height: 10)
                    }
                    .shimmer()
            }
        }
        .pinkCard()
    }

    // MARK: - Recommendations list

    @ViewBuilder
    private var recsList: some View {
        if vm.recommendations.isEmpty && !vm.isLoading {
            ContentUnavailableView(
                "No ideas yet",
                systemImage: "sparkles",
                description: Text("Tap Generate to get your first AI video concept")
            )
        } else {
            if !vm.recommendations.isEmpty {
                Text("Recent Ideas")
                    .font(.appCaption).fontWeight(.bold)
                    .foregroundStyle(Color.tiktokAccent)
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ForEach(Array(vm.recommendations.enumerated()), id: \.element.id) { i, rec in
                NavigationLink(destination: RecommendationDetailView(rec: rec)) {
                    RecommendationCardView(rec: rec, compact: i > 0)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
