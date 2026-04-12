import SwiftUI

struct CalendarSettingsView: View {
    let calendarModel: CalendarModel

    var body: some View {
        Form {
            Section {
                if calendarModel.isOptedIn {
                    Label("Calendar access enabled", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)

                    Button("Opt Out") {
                        calendarModel.optOut()
                    }
                } else {
                    Label("Calendar access not enabled", systemImage: "calendar.badge.exclamationmark")

                    Button("Enable Calendar") {
                        Task {
                            await calendarModel.requestAccess()
                        }
                    }
                }
            } header: {
                Text("Calendar Integration")
            } footer: {
                Text("When enabled, planned dates are added to your calendar and free/busy times help find availability.")
            }
        }
        .navigationTitle("Calendar")
    }
}
