import SwiftUI

struct GroupSettingsView: View {
    @Bindable var model: GroupModel
    @State private var showingCreateGroup = false
    @State private var shareURL: URL?
    @State private var showingShareSheet = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
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
                                        if case .success(let url) = result {
                                            shareURL = url
                                            showingShareSheet = true
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
            .buttonStyle(.plain)
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
