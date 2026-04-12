import SwiftUI

struct ContentView: View {
    @State private var ideasModel = IdeasModel(
        repository: FakeDateRepository(),
        groupIdentifier: "default-group",
        currentUserIdentifier: "current-user"
    )

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                HomeTab()
            }

            Tab("Discover", systemImage: "map") {
                DiscoverTab()
            }

            Tab("Ideas", systemImage: "lightbulb") {
                IdeasTab(model: ideasModel)
            }
        }
    }
}

#Preview {
    ContentView()
}
