import SwiftUI

struct OnboardingView: View {
    let groupRepository: GroupRepository
    let calendarService: CalendarService
    let notificationService: NotificationService
    let onComplete: (CalendarModel, NotificationModel) -> Void

    @State private var step = 0
    @State private var calendarModel: CalendarModel
    @State private var notificationModel: NotificationModel
    @State private var groupName = "Our Dates"
    @State private var isCreatingGroup = false
    @State private var groupError: SparkError?
    @State private var shareURL: URL?
    @State private var showingShareSheet = false

    init(
        groupRepository: GroupRepository,
        calendarService: CalendarService,
        notificationService: NotificationService,
        onComplete: @escaping (CalendarModel, NotificationModel) -> Void
    ) {
        self.groupRepository = groupRepository
        self.calendarService = calendarService
        self.notificationService = notificationService
        self.onComplete = onComplete
        self._calendarModel = State(initialValue: CalendarModel(calendarService: calendarService))
        self._notificationModel = State(initialValue: NotificationModel(notificationService: notificationService))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            currentPage
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut, value: step)

            OnboardingPageIndicator(count: 4, current: step)
                .padding(.bottom, 12)
        }
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
            OnboardingWelcomePage { nextStep() }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        case 1:
            OnboardingNotificationsPage(model: notificationModel) { nextStep() }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        case 2:
            OnboardingCalendarPage(model: calendarModel) { nextStep() }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        default:
            OnboardingGroupPage(
                groupName: $groupName,
                isCreating: isCreatingGroup,
                error: groupError,
                onCreateAndInvite: createAndInvite,
                onCreate: createGroup,
                onJoinInstead: complete
            )
            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        }
    }

    private func nextStep() {
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
        let trimmed = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isCreatingGroup = true
        groupError = nil

        let result = await groupRepository.createGroup(name: trimmed)

        switch result {
        case .success(let group):
            await action(group)
        case .failure(let error):
            groupError = error
            isCreatingGroup = false
        }
    }

    private func complete() {
        onComplete(calendarModel, notificationModel)
    }
}

// MARK: - Welcome

private struct OnboardingWelcomePage: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                Image(systemName: "sparkles")
                    .font(.system(size: 80))
                    .foregroundStyle(.yellow)
                    .symbolRenderingMode(.hierarchical)

                VStack(spacing: 12) {
                    Text("Welcome to Spark")
                        .font(.largeTitle.bold())

                    Text("Plan unforgettable dates together.\nGet ideas, vote, and make memories.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            OnboardingPrimaryButton(title: "Get Started", color: .accentColor, action: onContinue)
                .padding(.bottom, 56)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Notifications

private struct OnboardingNotificationsPage: View {
    let model: NotificationModel
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.orange)
                    .symbolRenderingMode(.hierarchical)

                VStack(spacing: 12) {
                    Text("Stay in the Loop")
                        .font(.largeTitle.bold())

                    Text("Get reminders before upcoming dates and prompts to write about your memories.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                if model.isAuthorized {
                    Label("Notifications enabled", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.headline)
                }
            }

            Spacer()

            VStack(spacing: 12) {
                if !model.isAuthorized {
                    OnboardingPrimaryButton(title: "Enable Notifications", color: .orange) {
                        Task {
                            await model.requestAuthorization()
                            onContinue()
                        }
                    }
                } else {
                    OnboardingPrimaryButton(title: "Continue", color: .orange, action: onContinue)
                }

                if !model.isAuthorized {
                    Button("Skip", action: onContinue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 56)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Calendar

private struct OnboardingCalendarPage: View {
    let model: CalendarModel
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                    .symbolRenderingMode(.hierarchical)

                VStack(spacing: 12) {
                    Text("Sync with Calendar")
                        .font(.largeTitle.bold())

                    Text("Automatically add planned dates to your calendar so you never miss one.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                if model.isOptedIn {
                    Label("Calendar access enabled", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.headline)
                }
            }

            Spacer()

            VStack(spacing: 12) {
                if !model.isOptedIn {
                    OnboardingPrimaryButton(title: "Enable Calendar", color: .blue) {
                        Task {
                            await model.requestAccess()
                            onContinue()
                        }
                    }
                } else {
                    OnboardingPrimaryButton(title: "Continue", color: .blue, action: onContinue)
                }

                if !model.isOptedIn {
                    Button("Skip", action: onContinue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 56)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Create Group

private struct OnboardingGroupPage: View {
    @Binding var groupName: String
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
            Spacer()

            VStack(spacing: 28) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.purple)
                    .symbolRenderingMode(.hierarchical)

                VStack(spacing: 12) {
                    Text("Create Your Group")
                        .font(.largeTitle.bold())

                    Text("Name your group and invite your partner to start planning together.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                TextField("Group name", text: $groupName)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
                    .font(.headline)

                if let error {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    onCreateAndInvite()
                } label: {
                    ZStack {
                        if isCreating {
                            ProgressView().tint(.white)
                        } else {
                            Text("Create & Invite Partner")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canCreate ? Color.purple : Color.secondary.opacity(0.3))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canCreate)

                Button {
                    onCreate()
                } label: {
                    Text("Create Without Inviting")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .disabled(!canCreate)

                Divider()
                    .padding(.vertical, 4)

                Button {
                    onJoinInstead()
                } label: {
                    Text("I've been invited to a group")
                        .font(.subheadline)
                        .foregroundStyle(.accentColor)
                }
            }
            .padding(.bottom, 56)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Shared Components

private struct OnboardingPrimaryButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(color)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

private struct OnboardingPageIndicator: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: index == current ? 20 : 8, height: 8)
                    .animation(.easeInOut, value: current)
            }
        }
    }
}
