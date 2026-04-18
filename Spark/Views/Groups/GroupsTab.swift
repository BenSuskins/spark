import SwiftUI

/// The 4th tab: the user's group hub. Hosts the currently-active group as a
/// hero, other groups as a switchable list, and create/join actions. A gear
/// icon in the toolbar opens the rest of Settings (calendar / notifications /
/// location).
struct GroupsTab: View {
    @Bindable var model: GroupModel
    var calendarModel: CalendarModel?
    var notificationModel: NotificationModel?
    var locationModel: LocationModel?

    @State private var showingCreateGroup = false
    @State private var showingSettings = false
    @State private var shareURL: ShareableURL?
    @State private var shareError: SparkError?
    @State private var groupToDelete: Group?
    @State private var groupToEdit: Group?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    if let current = model.selectedGroup {
                        GroupHeroCard(
                            group: current,
                            onShare: { share(current) },
                            onEdit: { groupToEdit = current }
                        )
                    } else {
                        EmptyGroupHero()
                    }

                    otherGroupsSection

                    actionsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .navigationTitle("Groups")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupSheet(model: model)
            }
            .sheet(item: $groupToEdit) { group in
                EditGroupSheet(model: model, group: group)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsSheet(
                    calendarModel: calendarModel,
                    notificationModel: notificationModel,
                    locationModel: locationModel
                )
            }
            .sheet(item: $shareURL) { item in
                ShareSheet(url: item.url)
            }
            .alert("Sharing failed", isPresented: Binding(
                get: { shareError != nil },
                set: { if !$0 { shareError = nil } }
            )) {
                Button("OK") { shareError = nil }
            } message: {
                if let shareError {
                    Text(shareError.localizedDescription)
                }
            }
            .confirmationDialog(
                "Delete group?",
                isPresented: Binding(
                    get: { groupToDelete != nil },
                    set: { if !$0 { groupToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let group = groupToDelete {
                        Task { await model.deleteGroup(group) }
                    }
                }
            } message: {
                Text("This will permanently delete the group and all of its dates, ideas, and journal entries.")
            }
        }
    }

    // MARK: - Sections

    private var otherGroupsSection: some View {
        let others = model.groups.filter { $0.id != model.selectedGroup?.id }

        return SwiftUI.Group {
            if !others.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your other groups")
                        .font(.title3.weight(.semibold))
                        .padding(.horizontal, 4)

                    VStack(spacing: 8) {
                        ForEach(others) { group in
                            GroupRowCard(
                                group: group,
                                onSelect: { model.selectGroup(group) },
                                onDelete: { groupToDelete = group }
                            )
                        }
                    }
                }
            }
        }
    }

    private var actionsSection: some View {
        Button {
            showingCreateGroup = true
        } label: {
            Label("Create group", systemImage: "plus")
        }
        .buttonStyle(SparkPrimaryButtonStyle())
    }

    // MARK: - Actions

    private func share(_ group: Group) {
        Task {
            let result = await model.shareGroup(group)
            switch result {
            case .success(let url):
                shareURL = ShareableURL(url: url)
            case .failure(let error):
                shareError = error
            }
        }
    }
}

// MARK: - Hero

private struct GroupHeroCard: View {
    let group: Group
    let onShare: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text(group.emoji)
                .font(.system(size: 72))

            Text(group.name)
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)

            Text("Created \(group.createdDate, style: .date)")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))

            HStack(spacing: 10) {
                Button {
                    onShare()
                } label: {
                    Label("Share & invite", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(HeroShareButtonStyle())

                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.28))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit group")
            }
        }
        .foregroundStyle(.white)
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [SparkColors.accent, SparkColors.accent.opacity(0.65)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 24, y: 8)
    }
}

private struct HeroShareButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 22)
            .background(.white.opacity(configuration.isPressed ? 0.18 : 0.28))
            .clipShape(Capsule())
    }
}

private struct EmptyGroupHero: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("🌱")
                .font(.system(size: 64))
            Text("Create your first group")
                .font(.title2.weight(.semibold))
            Text("Plan dates together with your partner or friends.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(SparkColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

// MARK: - Row

private struct GroupRowCard: View {
    let group: Group
    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Text(group.emoji)
                    .font(.system(size: 32))
                    .frame(width: 48, height: 48)
                    .background(SparkColors.accentMuted)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name)
                        .font(.headline)
                        .foregroundStyle(SparkColors.textPrimary)
                    Text("Switch to this group")
                        .font(.caption)
                        .foregroundStyle(SparkColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(SparkColors.textTertiary)
            }
            .padding(16)
            .background(SparkColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Shared types (moved here from the old GroupSettingsView)

struct ShareableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
