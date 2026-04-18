import SwiftUI
import SwiftData

struct ContentView: View {
    private let dateRepository: DateRepository
    private let groupRepository: GroupRepository
    private let cloudKitManager: CloudKitManager?
    private let modelContainer: ModelContainer

    init() {
        let container: ModelContainer
        do {
            container = try PersistenceContainer.create()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        self.modelContainer = container

        #if targetEnvironment(simulator)
        dateRepository = FakeDateRepository()
        groupRepository = FakeGroupRepository()
        cloudKitManager = nil
        #else
        let manager = CloudKitManager()
        cloudKitManager = manager
        let cloudKitDateRepo = CloudKitDateRepository(manager: manager)
        let cloudKitGroupRepo = CloudKitGroupRepository(manager: manager)
        dateRepository = CachedDateRepository(remote: cloudKitDateRepo, modelContainer: container)
        groupRepository = CachedGroupRepository(remote: cloudKitGroupRepo, modelContainer: container)
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
    @State private var locationModel: LocationModel?
    @State private var networkMonitor = NetworkMonitor()
    @State private var syncManager: SyncManager?

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                if let homeModel, let groupModel, let currentGroupId = groupModel.selectedGroupIdentifier {
                    HomeTab(
                        model: homeModel,
                        repository: dateRepository,
                        venueSearchService: venueSearchService,
                        groupIdentifier: currentGroupId
                    )
                }
            }

            Tab("Discover", systemImage: "map") {
                if let discoverModel {
                    DiscoverTab(model: discoverModel)
                }
            }

            Tab("Ideas", systemImage: "lightbulb") {
                if let ideasModel {
                    IdeasTab(
                        model: ideasModel,
                        homeModel: homeModel,
                        calendarModel: calendarModel,
                        notificationModel: notificationModel
                    )
                }
            }

            Tab("Groups", systemImage: "person.2.fill") {
                if let groupModel {
                    GroupsTab(
                        model: groupModel,
                        calendarModel: calendarModel,
                        notificationModel: notificationModel,
                        locationModel: locationModel
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
            ) { completedCalendar, completedNotif, completedLocation, completedGroup in
                calendarModel = completedCalendar
                notificationModel = completedNotif
                locationModel = completedLocation
                if let completedGroup {
                    groupModel?.selectGroup(completedGroup)
                }
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
            groupModel = gm

            if calendarModel == nil {
                calendarModel = CalendarModel(calendarService: calendarService)
            }

            if locationModel == nil {
                locationModel = LocationModel(locationService: locationService)
            }

            if notificationModel == nil {
                let nm = NotificationModel(notificationService: notificationService)
                if hasCompletedOnboarding {
                    await nm.requestAuthorization()
                }
                notificationModel = nm
            }

            createModels()

            #if !targetEnvironment(simulator)
            if let cloudKitManager {
                let sm = SyncManager(
                    modelContainer: modelContainer,
                    remoteDateRepository: CloudKitDateRepository(manager: cloudKitManager),
                    remoteGroupRepository: CloudKitGroupRepository(manager: cloudKitManager)
                )
                syncManager = sm
                networkMonitor.onConnectivityRestored = { await sm.syncPendingChanges() }
                networkMonitor.start()
            }
            #endif
        }
        .onChange(of: groupModel?.selectedGroupIdentifier) { _, _ in
            updateGroupSelection()
        }
        .onChange(of: groupModel?.groupIdentifiers) { _, _ in
            updateGroupSelection()
        }
        .onChange(of: hasCompletedOnboarding) { _, newValue in
            if newValue {
                Task {
                    await groupModel?.loadGroups()
                    createModels()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .cloudKitShareAccepted)) { _ in
            Task {
                await groupModel?.loadGroups()
                updateGroupSelection()
            }
        }
    }

    private func createModels() {
        guard let groupModel, let groupId = groupModel.selectedGroupIdentifier else { return }

        if homeModel == nil {
            homeModel = HomeModel(repository: dateRepository, currentUserIdentifier: currentUserIdentifier)
        }
        homeModel?.selectedGroupIdentifier = groupId

        if ideasModel == nil {
            ideasModel = IdeasModel(
                repository: dateRepository,
                groupIdentifier: groupId,
                currentUserIdentifier: currentUserIdentifier
            )
        }

        if discoverModel == nil {
            discoverModel = DiscoverModel(
                venueSearchService: venueSearchService,
                dateRepository: dateRepository,
                groupIdentifier: groupId,
                currentUserIdentifier: currentUserIdentifier
            )
        }
    }

    private func updateGroupSelection() {
        guard let groupModel, let groupId = groupModel.selectedGroupIdentifier else { return }

        homeModel?.selectedGroupIdentifier = groupId
        ideasModel?.updateGroup(groupId)
        discoverModel?.updateGroup(groupId)
    }
}

#Preview {
    ContentView()
}
