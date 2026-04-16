import SwiftUI

struct CalendarEntrySheet: View {
    var prefilledTitle: String? = nil
    var prefilledDate: Date = .now

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var scheduledAt: Date = .now
    @State private var status: String = "draft"
    @State private var isSaving = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.tiktokBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // Title
                        fieldSection(label: "Title", icon: "pencil") {
                            TextField("e.g. BookTok haul video", text: $title)
                                .font(.appBody)
                                .padding(12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        // Notes
                        fieldSection(label: "Notes", icon: "note.text") {
                            TextEditor(text: $notes)
                                .font(.appBody)
                                .frame(height: 80)
                                .padding(10)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        // Date & Time
                        fieldSection(label: "Date & Time", icon: "calendar") {
                            DatePicker("", selection: $scheduledAt, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(Color.tiktokAccent)
                                .padding(12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.appCaption2)
                                    .foregroundStyle(Color.tiktokAccent)
                                Text("Suggested: Tue 6:00 PM (your best slot)")
                                    .font(.appCaption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.tiktokAccent)
                            }
                        }

                        // Status
                        fieldSection(label: "Status", icon: "flag.fill") {
                            HStack(spacing: 8) {
                                statusPill("draft",     label: "📝 Draft")
                                statusPill("scheduled", label: "📅 Scheduled")
                                statusPill("posted",    label: "✅ Posted")
                            }
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.appCaption)
                                .foregroundStyle(Color.gradeF)
                        }

                        // Save button
                        Button {
                            Task { await save() }
                        } label: {
                            if isSaving {
                                ProgressView().tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            } else {
                                Text("Save Entry")
                                    .font(.appHeadline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }
                        }
                        .background(
                            LinearGradient(colors: [.tiktokAccent, .tiktokDarkAccent],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.tiktokAccent.opacity(0.35), radius: 10, x: 0, y: 4)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                    }
                    .padding(16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("New Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.tiktokAccent)
                }
            }
            .onAppear {
                title = prefilledTitle ?? ""
                scheduledAt = prefilledDate
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Field section wrapper

    private func fieldSection<Content: View>(label: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon)
                .font(.appCaption)
                .fontWeight(.bold)
                .foregroundStyle(Color.tiktokAccent)
                .textCase(.uppercase)
            content()
        }
    }

    // MARK: - Status pill

    private func statusPill(_ value: String, label: String) -> some View {
        let isActive = status == value
        return Button {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) { status = value }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(label)
                .font(.appCaption)
                .fontWeight(.bold)
                .foregroundStyle(isActive ? .white : Color.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(isActive ? value.statusColor : Color.white)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(isActive ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(IconButtonStyle())
    }

    // MARK: - Save

    private func save() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        let req = CalendarEntryRequest(
            title: title.trimmingCharacters(in: .whitespaces),
            notes: notes.isEmpty ? nil : notes,
            scheduledAt: scheduledAt,
            status: status,
            recommendationId: nil
        )
        do {
            let _: CalendarEntryResponse = try await APIClient.shared.request(.createCalendarEntry, body: req)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
