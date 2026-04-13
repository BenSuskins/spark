import SwiftUI

struct ContentView: View {
    private let dateRepository: DateRepository
    private let groupRepository: GroupRepository
    private let cloudKitManager: CloudKitManager?

    init() {
        #if targetEnvironment(simulator)
        dateRepository = FakeDateRepository()
        groupRepository = FakeGroupRepository()
        cloudKitManager = nil
        #else
        let manager = CloudKitManager()
        cloudKitManager = manager
        dateRepository = CloudKitDateRepository(manager: manager)
        groupRepository = CloudKitGroupRepository(manager: manager)
        #endif
    }
    private let venueSearchService: VenueSearchService = MapKitVenueSearchService()
    private let calendarService: CalendarService = EventKitCalendarService()
    private let notificationService: NotificationService = LocalNotificationService()
    private let locationService: LocationService = CoreLocationService()

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentUserIdentifier = "current-user"

    @State private var groupModel: GroupModel?
    @State private var homeModel: HomeModel?
    @State private var ideasModel: IdeasModel?
    @State private var discoverModel: DiscoverModel?
    @State private var calendarModel: CalendarModel?
    @State private var notificationModel: NotificationModel?

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                if let homeModel, let groupModel {
                    HomeTab(
                        model: homeModel,
                        repository: dateRepository,
                        venueSearchService: venueSearchService,
                        groupIdentifiers: groupModel.groupIdentifiers,
                        groupPickerMenu: GroupPickerMenu(model: groupModel, calendarModel: calendarModel, notificationModel: notificationModel)
                    )
                }
            }

            Tab("Discover", systemImage: "map") {
                if let discoverModel {
                    DiscoverTab(model: discoverModel)
                }
            }

            Tab("Ideas", systemImage: "lightbulb") {
                if let ideasModel, let groupModel {
                    IdeasTab(
                        model: ideasModel,
                        homeModel: homeModel,
                        calendarModel: calendarModel,
                        notificationModel: notificationModel,
                        groupPickerMenu: GroupPickerMenu(model: groupModel, calendarModel: calendarModel, notificationModel: notificationModel)
                    )
                }
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { !hasCompletedOnboarding },
            set: { _ in }
        )) {
            OnboardingView(
                groupRepository: groupRepository,
                calendarService: calendarService,
                notificationService: notificationService,
                locationService: locationService
            ) { completedCalendar, completedNotif, _ in
                calendarModel = completedCalendar
                notificationModel = completedNotif
                hasCompletedOnboarding = true
            }
        }
        .task {
            if let cloudKitManager {
                if case .success(let userId) = await cloudKitManager.currentUserIdentifier() {
                    currentUserIdentifier = userId
                }
            }

            let gm = GroupModel(repository: groupRepository)
            await gm.loadGroups()

            // Only auto-create a fallback group for returning users if all groups were deleted.
            // New users create their group during onboarding.
            if gm.groups.isEmpty && hasCompletedOnboarding {
                await gm.createGroup(name: "My Dates")
            }

            groupModel = gm

            if calendarModel == nil {
                calendarModel = CalendarModel(calendarService: calendarService)
            }

            if notificationModel == nil {
                let nm = NotificationModel(notificationService: notificationService)
                // Only request authorization for returning users — onboarding handles new users.
                if hasCompletedOnboarding {
                    await nm.requestAuthorization()
                }
                notificationModel = nm
            }

            rebuildModels()
        }
        .onChange(of: groupModel?.selectedGroupIdentifier) { _, _ in
            rebuildModels()
        }
        .onChange(of: groupModel?.groupIdentifiers) { _, _ in
            rebuildModels()
        }
        .onChange(of: hasCompletedOnboarding) { _, newValue in
            if newValue {
                // Reload groups after onboarding creates the first group.
                Task {
                    await groupModel?.loadGroups()
                    rebuildModels()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .cloudKitShareAccepted)) { _ in
            // An invite was accepted via the system share UI — reload so the shared group appears.
            Task {
                await groupModel?.loadGroups()
                rebuildModels()
            }
        }
    }

    private func rebuildModels() {
        guard let groupModel else { return }

        let groupId = groupModel.selectedGroupIdentifier ?? groupModel.groupIdentifiers.first ?? "default"

        homeModel = HomeModel(repository: dateRepository, currentUserIdentifier: currentUserIdentifier)
        homeModel?.selectedGroupIdentifier = groupModel.selectedGroupIdentifier

        ideasModel = IdeasModel(
            repository: dateRepository,
            groupIdentifier: groupId,
            currentUserIdentifier: currentUserIdentifier
        )

        discoverModel = DiscoverModel(
            venueSearchService: venueSearchService,
            dateRepository: dateRepository,
            groupIdentifier: groupId,
            currentUserIdentifier: currentUserIdentifier
        )
    }
}

#Preview {
    ContentView()
}
