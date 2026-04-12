import SwiftUI

struct ContentView: View {
    private let repository: DateRepository = FakeDateRepository()
    private let groupIdentifiers = ["default-group"]
    private let currentUserIdentifier = "current-user"

    @State private var homeModel: HomeModel?
    @State private var ideasModel: IdeasModel?

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                if let homeModel {
                    HomeTab(
                        model: homeModel,
                        repository: repository,
                        groupIdentifiers: groupIdentifiers
                    )
                }
            }

            Tab("Discover", systemImage: "map") {
                DiscoverTab()
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
        }
    }
}

#Preview {
    ContentView()
}
