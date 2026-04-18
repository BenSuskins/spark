import SwiftUI

/// 3-page onboarding flow:
///  1. Welcome
///  2. Permissions — calendar, notifications, location on a single page
///  3. Create group — emoji + name, with optional invite
struct OnboardingView: View {
    let groupRepository: GroupRepository
    let calendarService: CalendarService
    let notificationService: NotificationService
    let locationService: LocationService
    let onComplete: (CalendarModel, NotificationModel, LocationModel, Group?) -> Void

    @State private var step = 0
    @State private var calendarModel: CalendarModel
    @State private var notificationModel: NotificationModel
    @State private var locationModel: LocationModel
    @State private var groupName = "Our Dates"
    @State private var groupEmoji = "💞"
    @State private var isCreatingGroup = false
    @State private var groupError: SparkError?
    @State private var createdGroup: Group?
    @State private var shareURL: URL?
    @State private var showingShareSheet = false

    init(
        groupRepository: GroupRepository,
        calendarService: CalendarService,
        notificationService: NotificationService,
        locationService: LocationService,
        onComplete: @escaping (CalendarModel, NotificationModel, LocationModel, Group?) -> Void
    ) {
        self.groupRepository = groupRepository
        self.calendarService = calendarService
        self.notificationService = notificationService
        self.locationService = locationService
        self.onComplete = onComplete
        self._calendarModel = State(initialValue: CalendarModel(calendarService: calendarService))
        self._notificationModel = State(initialValue: NotificationModel(notificationService: notificationService))
        self._locationModel = State(initialValue: LocationModel(locationService: locationService))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            currentPage
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut, value: step)

            OnboardingPageIndicator(count: 3, current: step)
                .padding(.bottom, 12)
        }
        .background(SparkColors.background.ignoresSafeArea())
        .sheet(isPresented: $showingShareSheet, onDismiss: complete) {
            if let url = shareURL {
                ShareSheet(url: url)
            }
        }
    }

    @ViewBuilder
    private var currentPage: some View {
        switch step {
        case 0:
            OnboardingWelcomePage { advance() }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        case 1:
            OnboardingPermissionsPage(
                calendarModel: calendarModel,
                notificationModel: notificationModel,
                locationModel: locationModel,
                onContinue: { advance() }
            )
            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        default:
            OnboardingGroupPage(
                groupName: $groupName,
                groupEmoji: $groupEmoji,
                isCreating: isCreatingGroup,
                error: groupError,
                onCreateAndInvite: createAndInvite,
                onCreate: createGroup,
                onJoinInstead: complete
            )
            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        }
    }

    private func advance() {
        withAnimation { step += 1 }
    }

    private func createGroup() {
        Task { await performCreate { _ in complete() } }
    }

    private func createAndInvite() {
        Task {
            await performCreate { group in
                let result = await groupRepository.shareGroup(group)
                if case .success(let url) = result {
                    shareURL = url
                    showingShareSheet = true
                } else {
                    complete()
                }
            }
        }
    }

    private func performCreate(then action: @escaping (Group) async -> Void) async {
        let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        isCreatingGroup = true
        groupError = nil

        let result = await groupRepository.createGroup(name: trimmedName, emoji: groupEmoji)

        switch result {
        case .success(let group):
            createdGroup = group
            await action(group)
        case .failure(let error):
            groupError = error
            isCreatingGroup = false
        }
    }

    private func complete() {
        onComplete(calendarModel, notificationModel, locationModel, createdGroup)
    }
}

// MARK: - Welcome

private struct OnboardingWelcomePage: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Text("✨")
                    .font(.system(size: 88))

                VStack(spacing: 12) {
                    Text("Welcome to Spark")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(SparkColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Plan unforgettable dates together.\nGet ideas, vote, and make memories.")
                        .font(.body)
                        .foregroundStyle(SparkColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            Button("Get started", action: onContinue)
                .buttonStyle(SparkPrimaryButtonStyle())
                .padding(.bottom, 56)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Permissions (combined)

private struct OnboardingPermissionsPage: View {
    let calendarModel: CalendarModel
    let notificationModel: NotificationModel
    let locationModel: LocationModel
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Set you up")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(SparkColors.textPrimary)
                Text("Grant access so Spark can do its best work. You can change these anytime.")
                    .font(.body)
                    .foregroundStyle(SparkColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 24)

            VStack(spacing: 12) {
                PermissionRow(
                    emoji: "🔔",
                    title: "Notifications",
                    subtitle: "Gentle nudges before upcoming dates.",
                    isEnabled: notificationModel.isAuthorized,
                    action: { Task { await notificationModel.requestAuthorization() } }
                )
                PermissionRow(
                    emoji: "📆",
                    title: "Calendar",
                    subtitle: "Add planned dates to your calendar automatically.",
                    isEnabled: calendarModel.isOptedIn,
                    action: { Task { await calendarModel.requestAccess() } }
                )
                PermissionRow(
                    emoji: "📍",
                    title: "Location",
                    subtitle: "Find venues and date spots near you.",
                    isEnabled: locationModel.isAuthorized,
                    action: { Task { await locationModel.requestAuthorization() } }
                )
            }
            .padding(.top, 28)

            Spacer()

            Button("Continue", action: onContinue)
                .buttonStyle(SparkPrimaryButtonStyle())
                .padding(.bottom, 56)
        }
        .padding(.horizontal, 24)
    }
}

private struct PermissionRow: View {
    let emoji: String
    let title: String
    let subtitle: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.system(size: 28))
                .frame(width: 52, height: 52)
                .background(SparkColors.accentMuted)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(SparkColors.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(SparkColors.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            if isEnabled {
                Label("On", systemImage: "checkmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .font(.title3)
                    .foregroundStyle(SparkColors.success)
            } else {
                Button("Enable", action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SparkColors.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(SparkColors.accentMuted)
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .sparkCard(cornerRadius: 20)
    }
}

// MARK: - Create group

private struct OnboardingGroupPage: View {
    @Binding var groupName: String
    @Binding var groupEmoji: String
    let isCreating: Bool
    let error: SparkError?
    let onCreateAndInvite: () -> Void
    let onCreate: () -> Void
    let onJoinInstead: () -> Void

    var canCreate: Bool {
        !isCreating && !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Create your group")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(SparkColors.textPrimary)
                Text("Give it an emoji and a name — you can change these later.")
                    .font(.body)
                    .foregroundStyle(SparkColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 24)

            VStack(spacing: 20) {
                EmojiPickerChip(emoji: $groupEmoji)

                SparkFormField(title: "Group name") {
                    TextField("Our Dates", text: $groupName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(SparkColors.textPrimary)
                        .textInputAutocapitalization(.words)
                }

                if let error {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(SparkColors.destructive)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 28)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    onCreateAndInvite()
                } label: {
                    ZStack {
                        if isCreating {
                            ProgressView().tint(.white)
                        } else {
                            Text("Create & invite partner")
                        }
                    }
                }
                .buttonStyle(SparkPrimaryButtonStyle())
                .disabled(!canCreate)

                Button("Create without inviting", action: onCreate)
                    .buttonStyle(SparkGhostButtonStyle())
                    .disabled(!canCreate)

                Button("I've been invited to a group", action: onJoinInstead)
                    .buttonStyle(SparkGhostButtonStyle())
            }
            .padding(.bottom, 56)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Page indicator

private struct OnboardingPageIndicator: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? SparkColors.accent : SparkColors.textTertiary.opacity(0.4))
                    .frame(width: index == current ? 20 : 8, height: 8)
                    .animation(.easeInOut, value: current)
            }
        }
    }
}
