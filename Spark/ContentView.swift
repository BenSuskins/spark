import SwiftUI

struct ContentView: View {
    #if targetEnvironment(simulator)
    private let dateRepository: DateRepository = FakeDateRepository()
    private let groupRepository: GroupRepository = FakeGroupRepository()
    #else
    private let cloudKitManager = CloudKitManager()
    private var dateRepository: DateRepository { CloudKitDateRepository(manager: cloudKitManager) }
    private var groupRepository: GroupRepository { CloudKitGroupRepository(manager: cloudKitManager) }
    #endif
    private let venueSearchService: VenueSearchService = MapKitVenueSearchService()
    private let calendarService: CalendarService = EventKitCalendarService()
    private let notificationService: NotificationService = LocalNotificationService()
    private let currentUserIdentifier = "current-user"

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
                        groupIdentifiers: groupModel.groupIdentifiers
                    )
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            GroupPickerMenu(model: groupModel, calendarModel: calendarModel, notificationModel: notificationModel)
                        }
                    }
                }
            }

            Tab("Discover", systemImage: "map") {
                if let discoverModel {
                    DiscoverTab(model: discoverModel)
                }
            }

            Tab("Ideas", systemImage: "lightbulb") {
                if let ideasModel {
                    IdeasTab(model: ideasModel, homeModel: homeModel, calendarModel: calendarModel, notificationModel: notificationModel)
                        .toolbar {
                            if let groupModel {
                                ToolbarItem(placement: .topBarLeading) {
                                    GroupPickerMenu(model: groupModel, calendarModel: calendarModel, notificationModel: notificationModel)
                                }
                            }
                        }
                }
            }
        }
        .task {
            let gm = GroupModel(repository: groupRepository)
            await gm.loadGroups()

            if gm.groups.isEmpty {
                await gm.createGroup(name: "My Dates")
            }

            groupModel = gm
            calendarModel = CalendarModel(calendarService: calendarService)

            let nm = NotificationModel(notificationService: notificationService)
            await nm.requestAuthorization()
            notificationModel = nm

            rebuildModels()
        }
        .onChange(of: groupModel?.selectedGroupIdentifier) { _, _ in
            rebuildModels()
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
