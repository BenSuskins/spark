import SwiftUI
import CoreLocation

/// Four-step scheduling wizard: When → Where → Who → Review. The "Where"
/// step seeds the itinerary's first stop if supplied; otherwise the user can
/// build the itinerary later in `DateDetailView`.
struct PlanIdeaSheet: View {
    let idea: Idea
    let homeModel: HomeModel
    var calendarModel: CalendarModel?
    var notificationModel: NotificationModel?

    @Environment(\.dismiss) private var dismiss

    @State private var step: Int = 0
    @State private var selectedDate = defaultDate()
    @State private var venueName: String = ""
    @State private var addToCalendar = true
    @State private var scheduleReminder = true
    @State private var isCreating = false
    @State private var didCreate = false

    private static func defaultDate() -> Date {
        Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
    }

    private let totalSteps = 4

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar

                SwiftUI.Group {
                    switch step {
                    case 0: whenStep
                    case 1: whereStep
                    case 2: whoStep
                    default: reviewStep
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

                footer
            }
            .background(SparkColors.background)
            .navigationTitle(titleForStep)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(isCreating)
    }

    // MARK: - Progress

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? SparkColors.accent : SparkColors.accentMuted)
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .animation(SparkSprings.standard, value: step)
    }

    private var titleForStep: String {
        switch step {
        case 0: "When"
        case 1: "Where"
        case 2: "Who"
        default: "Review"
        }
    }

    // MARK: - Steps

    private var whenStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(emoji: "📆", title: "When is it?", subtitle: "Pick a date and time you're both free.")

                DatePicker("", selection: $selectedDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding(8)
                    .sparkCard(cornerRadius: 20)
            }
            .padding(16)
        }
    }

    private var whereStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(emoji: "📍", title: "Where to?", subtitle: "Optional — seeds the first stop of your itinerary.")

                SparkFormField(title: "First stop") {
                    TextField("Somewhere cosy, somewhere new", text: $venueName)
                        .font(.body)
                        .foregroundStyle(SparkColors.textPrimary)
                }

                Text("You can add more stops later in the date details.")
                    .font(.caption)
                    .foregroundStyle(SparkColors.textSecondary)
                    .padding(.horizontal, 4)
            }
            .padding(16)
        }
    }

    private var whoStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(emoji: "👥", title: "Who's coming?", subtitle: "This date lands in your current group.")

                HStack(spacing: 14) {
                    Text(idea.category.emoji)
                        .font(.system(size: 28))
                        .frame(width: 52, height: 52)
                        .background(SparkColors.accentMuted)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current group")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SparkColors.textSecondary)
                            .textCase(.uppercase)
                        Text("Everyone in this group will see the date.")
                            .font(.subheadline)
                            .foregroundStyle(SparkColors.textPrimary)
                    }
                    Spacer()
                }
                .padding(16)
                .sparkCard(cornerRadius: 20)
            }
            .padding(16)
        }
    }

    private var reviewStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(emoji: "✨", title: "Ready?", subtitle: "Confirm the details and we'll lock it in.")

                VStack(alignment: .leading, spacing: 12) {
                    ReviewRow(emoji: idea.category.emoji, title: idea.title, subtitle: idea.category.rawValue)
                    ReviewRow(
                        emoji: "📆",
                        title: selectedDate.formatted(date: .complete, time: .shortened),
                        subtitle: "Start time"
                    )
                    if !venueName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        ReviewRow(emoji: "📍", title: venueName, subtitle: "First stop")
                    }
                }

                VStack(spacing: 10) {
                    if let calendarModel, calendarModel.isOptedIn {
                        ToggleRow(emoji: "📆", title: "Add to calendar", isOn: $addToCalendar)
                    }
                    if let notificationModel, notificationModel.isAuthorized {
                        ToggleRow(emoji: "🔔", title: "Remind me beforehand", isOn: $scheduleReminder)
                    }
                }

                if didCreate {
                    Label("Date planned! ✨", systemImage: "checkmark.seal.fill")
                        .font(.headline)
                        .foregroundStyle(SparkColors.success)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(SparkColors.accentMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
            }
            .padding(16)
        }
    }

    private func stepHeader(emoji: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(emoji).font(.system(size: 40))
            Text(title)
                .font(.title.weight(.bold))
                .foregroundStyle(SparkColors.textPrimary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(SparkColors.textSecondary)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 10) {
            if step < totalSteps - 1 {
                Button("Continue") {
                    withAnimation(SparkSprings.sheet) { step += 1 }
                }
                .buttonStyle(SparkPrimaryButtonStyle())
            } else {
                Button {
                    createDate()
                } label: {
                    ZStack {
                        if isCreating {
                            ProgressView().tint(.white)
                        } else {
                            Text(didCreate ? "Done" : "Create date")
                        }
                    }
                }
                .buttonStyle(SparkPrimaryButtonStyle())
                .disabled(isCreating)
            }

            if step > 0 && !didCreate {
                Button("Back") {
                    withAnimation(SparkSprings.sheet) { step -= 1 }
                }
                .buttonStyle(SparkGhostButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    // MARK: - Create

    private func createDate() {
        guard !isCreating else { return }
        Task { await performCreate() }
    }

    private func performCreate() async {
        isCreating = true
        let endDate = selectedDate.addingTimeInterval(7200)
        let result = await homeModel.promoteIdeaToDate(idea, date: selectedDate)

        switch result {
        case .success(let plannedDate):
            if let calendarModel, calendarModel.isOptedIn, addToCalendar {
                _ = await calendarModel.createEvent(
                    title: idea.title,
                    start: selectedDate,
                    end: endDate,
                    notes: nil
                )
            }
            if let notificationModel, notificationModel.isAuthorized, scheduleReminder {
                await notificationModel.scheduleDateReminder(for: plannedDate)
                await notificationModel.scheduleJournalPrompt(for: plannedDate)
            }
            withAnimation(SparkSprings.celebratory) { didCreate = true }
            try? await Task.sleep(for: .seconds(1.2))
            dismiss()
        case .failure:
            isCreating = false
        }
    }
}

// MARK: - Bits

private struct ReviewRow: View {
    let emoji: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.system(size: 24))
                .frame(width: 44, height: 44)
                .background(SparkColors.accentMuted)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SparkColors.textSecondary)
                    .textCase(.uppercase)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(SparkColors.textPrimary)
            }
            Spacer()
        }
        .padding(14)
        .sparkCard(cornerRadius: 20)
    }
}

private struct ToggleRow: View {
    let emoji: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            Text(emoji).font(.system(size: 22))
            Text(title)
                .font(.headline)
                .foregroundStyle(SparkColors.textPrimary)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(SparkColors.accent)
        }
        .padding(14)
        .sparkCard(cornerRadius: 18)
    }
}
