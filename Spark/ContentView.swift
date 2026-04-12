import SwiftUI

struct ContentView: View {
    private let dateRepository: DateRepository = FakeDateRepository()
    private let groupRepository: GroupRepository = FakeGroupRepository()
    private let venueSearchService: VenueSearchService = MapKitVenueSearchService()
    private let currentUserIdentifier = "current-user"

    @State private var groupModel: GroupModel?
    @State private var homeModel: HomeModel?
    @State private var ideasModel: IdeasModel?
    @State private var discoverModel: DiscoverModel?

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
                            GroupPickerMenu(model: groupModel)
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
                    IdeasTab(model: ideasModel, homeModel: homeModel)
                        .toolbar {
                            if let groupModel {
                                ToolbarItem(placement: .topBarLeading) {
                                    GroupPickerMenu(model: groupModel)
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
