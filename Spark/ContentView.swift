import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                HomeTab()
            }

            Tab("Discover", systemImage: "map") {
                DiscoverTab()
            }

            Tab("Ideas", systemImage: "lightbulb") {
                IdeasTab()
            }
        }
    }
}

#Preview {
    ContentView()
}
