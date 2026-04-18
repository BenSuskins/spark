import SwiftUI
import MapKit

/// Half-map / half-list interface for venue discovery. The list is a draggable
/// sheet overlaying the map with three detents (small / medium / large). Tapping
/// a venue opens the `VenueDetailSheet`.
struct DiscoverTab: View {
    var model: DiscoverModel

    @State private var searchText = ""
    @State private var selectedVenue: Venue?
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var listDetent: PresentationDetent = .fraction(0.32)

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
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: .constant(true)) {
            DiscoverListSheet(
                model: model,
                searchText: $searchText,
                selectedVenue: $selectedVenue
            )
            .presentationDetents(
                [.fraction(0.18), .fraction(0.55), .large],
                selection: $listDetent
            )
            .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.55)))
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .interactiveDismissDisabled(true)
            .sheet(item: $selectedVenue) { venue in
                VenueDetailSheet(venue: venue, model: model)
            }
        }
    }
}

// MARK: - Draggable list sheet

private struct DiscoverListSheet: View {
    var model: DiscoverModel
    @Binding var searchText: String
    @Binding var selectedVenue: Venue?

    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 14) {
            searchField

            if model.isSearching {
                ProgressView()
                    .padding(.top, 12)
                Spacer()
            } else if model.venues.isEmpty {
                emptyState
                    .padding(.top, 8)
                Spacer(minLength: 0)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(model.venues) { venue in
                            VenuePhotoCard(venue: venue) {
                                selectedVenue = venue
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
        }
        .padding(.top, 12)
        .background(SparkColors.background)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(SparkColors.textSecondary)
            TextField("Search cafes, parks, bars…", text: $searchText)
                .focused($searchFocused)
                .submitLabel(.search)
                .onSubmit {
                    Task { await model.search(query: searchText) }
                }
                .onChange(of: searchText) { _, newValue in
                    if newValue.isEmpty {
                        Task { await model.search(query: "") }
                    }
                }
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchFocused = false
                    Task { await model.search(query: "") }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(SparkColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(SparkColors.surface, in: Capsule())
        .padding(.horizontal, 16)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("🗺️").font(.system(size: 40))
            Text("Find somewhere to go")
                .font(.headline)
                .foregroundStyle(SparkColors.textPrimary)
            Text("Search the map for venues, then add the best ones to Ideas.")
                .font(.subheadline)
                .foregroundStyle(SparkColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}
