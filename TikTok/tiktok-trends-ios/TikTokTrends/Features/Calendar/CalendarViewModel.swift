import Foundation

@Observable
final class CalendarViewModel {
    var entries: [CalendarEntryResponse] = []
    var selectedDate: Date = .now
    var isLoading = false
    var errorMessage: String?
    var showEntrySheet = false
    var editingEntry: CalendarEntryResponse?

    var currentMonth: Date = Calendar.current.startOfMonth(for: .now)

    // Entries keyed by day-of-month for the displayed month
    var entriesByDay: [Int: [CalendarEntryResponse]] {
        let cal = Calendar.current
        return Dictionary(grouping: entries) { entry in
            guard let date = entry.scheduledAt else { return 0 }
            return cal.component(.day, from: date)
        }
    }

    var selectedDayEntries: [CalendarEntryResponse] {
        let cal = Calendar.current
        let day = cal.component(.day, from: selectedDate)
        return entriesByDay[day] ?? []
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let month = formatter.string(from: currentMonth)
        do {
            entries = try await APIClient.shared.request(.calendarEntries(month: month))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ entry: CalendarEntryResponse) async {
        do {
            try await APIClient.shared.requestVoid(.deleteCalendarEntry(id: entry.id))
            entries.removeAll { $0.id == entry.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func nextMonth() async {
        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        await load()
    }

    func prevMonth() async {
        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        await load()
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}
