import SwiftUI
import MapKit

struct DiscoverTab: View {
    var model: DiscoverModel
    @State private var searchText = ""
    @State private var isSearchFocused = false
    @State private var selectedVenue: Venue?
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @FocusState private var searchFieldFocused: Bool

    var body: some View {
        Map(position: $cameraPosition, selection: $selectedVenue) {
            ForEach(model.venues) { venue in
                Marker(venue.name, coordinate: venue.coordinate)
                    .tag(venue)
            }
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            model.userCoordinate = context.camera.centerCoordinate
        }
        .overlay(alignment: .top) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search nearby venues", text: $searchText)
                    .focused($searchFieldFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        Task { await model.search(query: searchText) }
                    }
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchFieldFocused = false
                        Task { await model.search(query: "") }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .glassEffect(.regular.interactive(), in: .capsule)
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .overlay(alignment: .bottom) {
            if !model.venues.isEmpty {
                VenueListOverlay(
                    venues: model.venues,
                    selectedVenue: $selectedVenue
                )
            }
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

#Preview {
    DiscoverTab(model: DiscoverModel(
        venueSearchService: FakeVenueSearchService(),
        dateRepository: FakeDateRepository(),
        groupIdentifier: "preview-group",
        currentUserIdentifier: "preview-user"
    ))
}
