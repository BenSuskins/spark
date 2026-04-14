import SwiftUI

struct PlanIdeaSheet: View {
    let idea: Idea
    let homeModel: HomeModel
    var calendarModel: CalendarModel?
    var notificationModel: NotificationModel?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var addToCalendar = true
    @State private var didCreate = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Idea", value: idea.title)
                    LabeledContent("Category", value: idea.category.rawValue)
                }

                Section {
                    DatePicker("Date & Time", selection: $selectedDate)
                }

                if let calendarModel, calendarModel.isOptedIn {
                    Section {
                        Toggle("Add to Calendar", isOn: $addToCalendar)
                    }
                }

                if didCreate {
                    Section {
                        Label("Date planned!", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(SparkColors.success)
                    }
                }
            }
            .navigationTitle("Plan Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            let endDate = selectedDate.addingTimeInterval(7200)
                            let result = await homeModel.promoteIdeaToDate(idea, date: selectedDate)
                            if case .success(let plannedDate) = result {
                                if addToCalendar, let calendarModel, calendarModel.isOptedIn {
                                    _ = await calendarModel.createEvent(
                                        title: idea.title,
                                        start: selectedDate,
                                        end: endDate,
                                        notes: nil
                                    )
                                }
                                if let notificationModel {
                                    await notificationModel.scheduleDateReminder(for: plannedDate)
                                    await notificationModel.scheduleJournalPrompt(for: plannedDate)
                                }
                                didCreate = true
                                try? await Task.sleep(for: .seconds(0.8))
                                dismiss()
                            }
                        }
                    }
                    .disabled(didCreate)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
