import SwiftUI

struct GroupSettingsView: View {
    @Bindable var model: GroupModel
    var calendarModel: CalendarModel?
    var notificationModel: NotificationModel?
    @State private var showingCreateGroup = false
    @State private var shareURL: URL?
    @State private var showingShareSheet = false
    @State private var shareError: SparkError?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let calendarModel {
                        NavigationLink {
                            CalendarSettingsView(calendarModel: calendarModel)
                        } label: {
                            Label {
                                Text("Calendar")
                            } icon: {
                                Image(systemName: calendarModel.isOptedIn ? "calendar.badge.checkmark" : "calendar")
                                    .foregroundStyle(calendarModel.isOptedIn ? .green : .secondary)
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
                                    .foregroundStyle(notificationModel.isAuthorized ? .green : .secondary)
                            }
                        }
                    }
                }

                Section("Your Groups") {
                    if model.groups.isEmpty {
                        ContentUnavailableView(
                            "No Groups",
                            systemImage: "person.2",
                            description: Text("Create a group to start planning dates together")
                        )
                    } else {
                        ForEach(model.groups) { group in
                            GroupRow(
                                group: group,
                                onShare: {
                                    Task {
                                        let result = await model.shareGroup(group)
                                        switch result {
                                        case .success(let url):
                                            shareURL = url
                                            showingShareSheet = true
                                        case .failure(let error):
                                            shareError = error
                                        }
                                    }
                                }
                            )
                        }
                        .onDelete { indexSet in
                            Task {
                                for index in indexSet {
                                    await model.deleteGroup(model.groups[index])
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Groups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateGroup = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupSheet(model: model)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let shareURL {
                    ShareSheet(url: shareURL)
                }
            }
            .alert("Sharing Failed", isPresented: Binding(
                get: { shareError != nil },
                set: { if !$0 { shareError = nil } }
            )) {
                Button("OK") { shareError = nil }
            } message: {
                if let shareError {
                    Text(shareError.localizedDescription)
                }
            }
        }
    }
}

struct GroupRow: View {
    let group: Group
    let onShare: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.body)

                Text("Created \(group.createdDate, style: .date)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
            }
            .buttonStyle(.borderless)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
