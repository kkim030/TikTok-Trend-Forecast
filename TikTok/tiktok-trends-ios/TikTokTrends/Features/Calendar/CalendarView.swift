import SwiftUI

struct CalendarView: View {
    @State private var vm = CalendarViewModel()
    @State private var showEntrySheet = false
    @State private var showOptimalTiming = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdays = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.tiktokBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        monthHeader
                        weekdayHeader
                        calendarGrid
                        Divider().padding(.vertical, 12)
                        selectedDaySection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
                .refreshable { await vm.load() }

                // FAB
                Button { showEntrySheet = true } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            LinearGradient(colors: [.tiktokAccent, .tiktokDarkAccent],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(Circle())
                        .shadow(color: Color.tiktokAccent.opacity(0.45), radius: 14, x: 0, y: 6)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 90)
            }
            .navigationTitle("Calendar 🗓️")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showOptimalTiming = true
                    } label: {
                        Text("Best Times 🕐")
                            .font(.appCaption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.tiktokAccent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.tiktokAccent.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            .sheet(isPresented: $showEntrySheet, onDismiss: { Task { await vm.load() } }) {
                CalendarEntrySheet(prefilledTitle: nil, prefilledDate: vm.selectedDate)
            }
            .navigationDestination(isPresented: $showOptimalTiming) {
                OptimalTimingView()
            }
            .task { await vm.load() }
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button { Task { await vm.prevMonth() } } label: {
                Image(systemName: "chevron.left")
                    .font(.appHeadline)
                    .foregroundStyle(Color.tiktokAccent)
                    .frame(width: 32, height: 32)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.tiktokPrimary.opacity(0.3), radius: 6)
            }

            Spacer()

            Text(vm.currentMonth, format: .dateTime.month(.wide).year())
                .font(.appTitle2)
                .foregroundStyle(Color.tiktokDarkAccent)

            Spacer()

            Button { Task { await vm.nextMonth() } } label: {
                Image(systemName: "chevron.right")
                    .font(.appHeadline)
                    .foregroundStyle(Color.tiktokAccent)
                    .frame(width: 32, height: 32)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.tiktokPrimary.opacity(0.3), radius: 6)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        HStack(spacing: 4) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.appCaption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 6)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let cal = Calendar.current
        let firstWeekday = cal.component(.weekday, from: vm.currentMonth) - 1
        let daysInMonth = cal.range(of: .day, in: .month, for: vm.currentMonth)?.count ?? 30
        let totalCells = firstWeekday + daysInMonth
        let rows = Int(ceil(Double(totalCells) / 7.0))

        return LazyVGrid(columns: columns, spacing: 4) {
            // Leading empty cells
            ForEach(0..<firstWeekday, id: \.self) { _ in Color.clear.aspectRatio(1, contentMode: .fit) }

            // Day cells
            ForEach(1...daysInMonth, id: \.self) { day in
                DayCell(
                    day: day,
                    isToday: isToday(day),
                    isSelected: isSelected(day),
                    entries: vm.entriesByDay[day] ?? []
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        vm.selectedDate = dateFor(day: day)
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }
    }

    // MARK: - Selected Day

    @ViewBuilder
    private var selectedDaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(vm.selectedDate, format: .dateTime.weekday(.wide).month(.wide).day())
                .font(.appHeadline)
                .foregroundStyle(Color.tiktokDarkAccent)

            if vm.selectedDayEntries.isEmpty {
                Text("No videos scheduled")
                    .font(.appSubheadline)
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                ForEach(vm.selectedDayEntries) { entry in
                    CalendarEntryRow(entry: entry) {
                        Task { await vm.delete(entry) }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func isToday(_ day: Int) -> Bool {
        let cal = Calendar.current
        let today = cal.dateComponents([.year, .month, .day], from: .now)
        let monthComps = cal.dateComponents([.year, .month], from: vm.currentMonth)
        return today.year == monthComps.year && today.month == monthComps.month && today.day == day
    }

    private func isSelected(_ day: Int) -> Bool {
        let cal = Calendar.current
        let selComps = cal.dateComponents([.year, .month, .day], from: vm.selectedDate)
        let monthComps = cal.dateComponents([.year, .month], from: vm.currentMonth)
        return selComps.year == monthComps.year && selComps.month == monthComps.month && selComps.day == day
    }

    private func dateFor(day: Int) -> Date {
        var comps = Calendar.current.dateComponents([.year, .month], from: vm.currentMonth)
        comps.day = day
        return Calendar.current.date(from: comps) ?? .now
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let day: Int
    var isToday: Bool = false
    var isSelected: Bool = false
    let entries: [CalendarEntryResponse]

    var body: some View {
        VStack(spacing: 3) {
            Text("\(day)")
                .font(.appCaption)
                .fontWeight(.bold)
                .foregroundStyle(isToday ? .white : Color.primary)

            // Status dots
            if !entries.isEmpty {
                HStack(spacing: 2) {
                    ForEach(entries.prefix(3)) { entry in
                        Circle()
                            .fill(entry.status.statusColor)
                            .frame(width: 5, height: 5)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isToday ? Color.tiktokAccent : isSelected ? Color.tiktokAccent.opacity(0.1) : Color.white)
                .shadow(color: Color.tiktokPrimary.opacity(isToday || isSelected ? 0 : 0.15),
                        radius: 4, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(isSelected && !isToday ? Color.tiktokAccent : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Entry Row

struct CalendarEntryRow: View {
    let entry: CalendarEntryResponse
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Color bar
            RoundedRectangle(cornerRadius: 2)
                .fill(entry.status.statusColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.appSubheadline).fontWeight(.bold).foregroundStyle(Color.primary)
                if let date = entry.scheduledAt {
                    Text(date, format: .dateTime.hour().minute())
                        .font(.appCaption2).foregroundStyle(Color.secondary)
                }
            }

            Spacer()

            // Status badge
            Text(entry.status.statusLabel)
                .font(.appCaption2).fontWeight(.bold)
                .foregroundStyle(entry.status.statusColor)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(entry.status.statusColor.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.tiktokPrimary.opacity(0.15), radius: 6, x: 0, y: 2)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Status helpers

extension String {
    var statusColor: Color {
        switch self.lowercased() {
        case "scheduled": return .tiktokAccent
        case "posted":    return .tiktokMint.mix(with: .teal, by: 0.4)
        case "draft":     return .tiktokLavender.mix(with: .purple, by: 0.4)
        default:          return .gray
        }
    }
    var statusLabel: String {
        switch self.lowercased() {
        case "scheduled": return "📅 Scheduled"
        case "posted":    return "✅ Posted"
        case "draft":     return "📝 Draft"
        default:          return self.capitalized
        }
    }
}
