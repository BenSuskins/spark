import SwiftUI

struct ContentView: View {
    private let repository: DateRepository = FakeDateRepository()
    private let venueSearchService: VenueSearchService = MapKitVenueSearchService()
    private let groupIdentifiers = ["default-group"]
    private let currentUserIdentifier = "current-user"

    @State private var homeModel: HomeModel?
    @State private var ideasModel: IdeasModel?
    @State private var discoverModel: DiscoverModel?

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                if let homeModel {
                    HomeTab(
                        model: homeModel,
                        repository: repository,
                        venueSearchService: venueSearchService,
                        groupIdentifiers: groupIdentifiers
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
                    IdeasTab(model: ideasModel)
                }
            }
        }
        .task {
            homeModel = HomeModel(repository: repository, currentUserIdentifier: currentUserIdentifier)
            ideasModel = IdeasModel(
                repository: repository,
                groupIdentifier: groupIdentifiers.first!,
                currentUserIdentifier: currentUserIdentifier
            )
            discoverModel = DiscoverModel(
                venueSearchService: venueSearchService,
                dateRepository: repository,
                groupIdentifier: groupIdentifiers.first!,
                currentUserIdentifier: currentUserIdentifier
            )
        }
    }
}

#Preview {
    ContentView()
}
