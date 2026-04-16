import SwiftUI

struct TrendsView: View {
    @State private var vm = TrendsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tiktokBackground.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 10, pinnedViews: [.sectionHeaders]) {
                        Section {
                            bentoGrid
                                .padding(.horizontal, 16)
                        } header: {
                            segmentedPicker
                                .background(Color.tiktokBackground)
                        }
                    }
                    .padding(.bottom, 24)
                }
                .refreshable { await vm.refresh() }

                if vm.isLoading && vm.trends.isEmpty {
                    loadingSkeleton
                }

                if let error = vm.errorMessage {
                    ContentUnavailableView(error, systemImage: "wifi.slash")
                }
            }
            .navigationTitle("Trends ✨")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AvatarButton()
                }
            }
            .task { await vm.load() }
        }
    }

    // MARK: - Segmented Picker

    private var segmentedPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TrendSegment.allCases, id: \.self) { seg in
                    Button(seg.rawValue) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            vm.selectedSegment = seg
                        }
                    }
                    .font(.appSubheadline)
                    .fontWeight(vm.selectedSegment == seg ? .bold : .medium)
                    .foregroundStyle(vm.selectedSegment == seg ? .white : Color.tiktokDarkAccent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(vm.selectedSegment == seg ? Color.tiktokAccent : Color.white)
                            .shadow(color: vm.selectedSegment == seg
                                    ? Color.tiktokAccent.opacity(0.35) : Color.clear,
                                    radius: 8, x: 0, y: 2)
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Bento Grid

    @ViewBuilder
    private var bentoGrid: some View {
        let trends = vm.displayedTrends

        if trends.isEmpty && !vm.isLoading {
            ContentUnavailableView("No trends yet", systemImage: "chart.line.uptrend.xyaxis",
                                   description: Text("Pull down to refresh"))
        } else {
            // Chunk into groups of 3: [featured, narrow+narrow, wide+narrow, ...]
            let groups = stride(from: 0, to: trends.count, by: 3).map {
                Array(trends[$0..<min($0 + 3, trends.count)])
            }

            ForEach(Array(groups.enumerated()), id: \.offset) { i, group in
                bentoGroup(group, groupIndex: i)
            }
        }
    }

    @ViewBuilder
    private func bentoGroup(_ group: [TrendResponse], groupIndex: Int) -> some View {
        // First group: featured wide + 2 narrow
        // Even groups after: wide+narrow
        // Odd groups: 2 narrow
        if groupIndex == 0, let first = group.first {
            NavigationLink(destination: TrendDetailView(trend: first)) {
                TrendCardView(trend: first, size: .featured)
            }
            .buttonStyle(.plain)

            if group.count > 1 {
                HStack(spacing: 10) {
                    ForEach(group.dropFirst()) { trend in
                        NavigationLink(destination: TrendDetailView(trend: trend)) {
                            TrendCardView(trend: trend, size: .narrow)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        } else if groupIndex % 2 == 0, group.count >= 2 {
            // Wide + narrow
            HStack(spacing: 10) {
                NavigationLink(destination: TrendDetailView(trend: group[0])) {
                    TrendCardView(trend: group[0], size: .wide)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)

                NavigationLink(destination: TrendDetailView(trend: group[1])) {
                    TrendCardView(trend: group[1], size: .narrow)
                }
                .buttonStyle(.plain)
                .frame(width: UIScreen.main.bounds.width * 0.33)
            }
        } else {
            // 2 narrow
            HStack(spacing: 10) {
                ForEach(group) { trend in
                    NavigationLink(destination: TrendDetailView(trend: trend)) {
                        TrendCardView(trend: trend, size: .narrow)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Loading Skeleton

    private var loadingSkeleton: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 20).fill(Color.white).frame(height: 130)
                .shimmer()
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 20).fill(Color.white).frame(height: 160)
                    .shimmer()
                RoundedRectangle(cornerRadius: 20).fill(Color.white).frame(height: 160)
                    .shimmer()
            }
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 20).fill(Color.white).frame(height: 130)
                    .shimmer()
                RoundedRectangle(cornerRadius: 20).fill(Color.white).frame(height: 130)
                    .shimmer()
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Avatar Button (nav bar)

struct AvatarButton: View {
    @Environment(AuthManager.self) private var auth

    var body: some View {
        NavigationLink(destination: ProfileView()) {
            if let url = auth.currentUser?.avatarUrl, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    initialsView
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            } else {
                initialsView
            }
        }
    }

    private var initialsView: some View {
        Circle()
            .fill(LinearGradient(colors: [.tiktokPrimary, .tiktokAccent],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 32, height: 32)
            .overlay(
                Text(auth.currentUser?.tiktokHandle.prefix(1).uppercased() ?? "?")
                    .font(.appCaption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            )
    }
}
