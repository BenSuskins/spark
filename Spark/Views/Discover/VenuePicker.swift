import SwiftUI
import MapKit

struct VenuePicker: View {
    let venueSearchService: VenueSearchService
    let onSelect: (Venue) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var results: [Venue] = []
    @State private var isSearching = false
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var searchCoordinate = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Map(position: $cameraPosition) {
                    ForEach(results) { venue in
                        Marker(venue.name, coordinate: venue.coordinate)
                    }
                }
                .onMapCameraChange(frequency: .onEnd) { context in
                    searchCoordinate = context.camera.centerCoordinate
                }
                .frame(height: 200)

                List(results) { venue in
                    Button {
                        onSelect(venue)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(venue.name)
                                .font(.body)

                            if let address = venue.address {
                                Text(address)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .overlay {
                    if results.isEmpty && !searchText.isEmpty && !isSearching {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
            }
            .navigationTitle("Find Venue")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search for a place")
            .onSubmit(of: .search) {
                Task { await performSearch() }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func performSearch() async {
        isSearching = true
        let result = await venueSearchService.search(query: searchText, near: searchCoordinate)

        if case .success(let venues) = result {
            results = venues
        }
        isSearching = false
    }
}
