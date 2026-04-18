import SwiftUI

/// Settings sheet reachable from the Groups tab gear icon. Standard iOS Form.
/// Only contains integration toggles — group management lives in `GroupsTab`.
struct SettingsSheet: View {
    var calendarModel: CalendarModel?
    var notificationModel: NotificationModel?
    var locationModel: LocationModel?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Integrations") {
                    if let calendarModel {
                        NavigationLink {
                            CalendarSettingsView(calendarModel: calendarModel)
                        } label: {
                            Label {
                                Text("Calendar")
                            } icon: {
                                Image(systemName: calendarModel.isOptedIn ? "calendar.badge.checkmark" : "calendar")
                                    .foregroundStyle(calendarModel.isOptedIn ? SparkColors.success : .secondary)
                            }
                        }
                    }

                    if let notificationModel {
                        NavigationLink {
                            NotificationSettingsView(notificationModel: notificationModel)
                        } label: {
                            Label {
                                Text("Notifications")
                            } icon: {
                                Image(systemName: notificationModel.isAuthorized ? "bell.badge.fill" : "bell.slash")
                                    .foregroundStyle(notificationModel.isAuthorized ? SparkColors.success : .secondary)
                            }
                        }
                    }

                    if let locationModel {
                        Label {
                            HStack {
                                Text("Location")
                                Spacer()
                                if locationModel.isAuthorized {
                                    Text("Enabled")
                                        .foregroundStyle(.secondary)
                                } else {
                                    Button("Enable") {
                                        Task { await locationModel.requestAuthorization() }
                                    }
                                }
                            }
                        } icon: {
                            Image(systemName: locationModel.isAuthorized ? "location.fill" : "location.slash")
                                .foregroundStyle(locationModel.isAuthorized ? SparkColors.success : .secondary)
                        }
                    }
                }

                Section("About") {
                    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                        LabeledContent("Version", value: version)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
