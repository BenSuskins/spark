import SwiftUI
import MapKit

struct DiscoverTab: View {
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)

    var body: some View {
        NavigationStack {
            Map(position: $position) {
            }
            .navigationTitle("Discover")
        }
    }
}

#Preview {
    DiscoverTab()
}
