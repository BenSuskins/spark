import SwiftUI

struct NotificationSettingsView: View {
    let notificationModel: NotificationModel

    var body: some View {
        Form {
            Section {
                if notificationModel.isAuthorized {
                    Label("Notifications enabled", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Label("Notifications not enabled", systemImage: "bell.badge.slash")

                    Button("Enable Notifications") {
                        Task {
                            await notificationModel.requestAuthorization()
                        }
                    }
                }
            } header: {
                Text("Notifications")
            } footer: {
                Text("Get reminders before upcoming dates and prompts to write journal entries.")
            }
        }
        .navigationTitle("Notifications")
    }
}
