import SwiftUI
import MapKit

struct DiscoverTab: View {
    var model: DiscoverModel
    @State private var searchText = ""
    @State private var selectedVenue: Venue?
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition, selection: $selectedVenue) {
                ForEach(model.venues) { venue in
                    Marker(venue.name, coordinate: venue.coordinate)
                        .tag(venue)
                }
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                model.userCoordinate = context.camera.centerCoordinate
            }
            .overlay(alignment: .bottom) {
                if !model.venues.isEmpty {
                    VenueListOverlay(
                        venues: model.venues,
                        selectedVenue: $selectedVenue
                    )
                }
            }
            .navigationTitle("Discover")
            .searchable(text: $searchText, prompt: "Search nearby venues")
            .onSubmit(of: .search) {
                Task { await model.search(query: searchText) }
            }
            .onChange(of: searchText) { _, newValue in
                if newValue.isEmpty {
                    Task { await model.search(query: "") }
                }
            }
            .sheet(item: $selectedVenue) { venue in
                VenueDetailSheet(venue: venue, model: model)
            }
        }
    }
}

#Preview {
    DiscoverTab(model: DiscoverModel(
        venueSearchService: FakeVenueSearchService(),
        dateRepository: FakeDateRepository(),
        groupIdentifier: "preview-group",
        currentUserIdentifier: "preview-user"
    ))
}
