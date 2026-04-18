import SwiftUI
import MapKit

/// Half-map / half-list interface for venue discovery. The list is a bottom
/// overlay panel (not a system sheet) so the tab bar stays visible. Drag the
/// grabber to expand/collapse. Tapping a venue opens the `VenueDetailSheet`.
struct DiscoverTab: View {
    var model: DiscoverModel

    @State private var searchText = ""
    @State private var selectedVenue: Venue?
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var isExpanded = false

    var body: some View {
        GeometryReader { proxy in
            let collapsedHeight = max(proxy.size.height * 0.38, 260)
            let expandedHeight = proxy.size.height * 0.82
            let panelHeight = isExpanded ? expandedHeight : collapsedHeight

            ZStack(alignment: .bottom) {
                Map(position: $cameraPosition, selection: $selectedVenue) {
                    ForEach(model.venues) { venue in
                        Marker(venue.name, coordinate: venue.coordinate)
                            .tag(venue)
                    }
                }
                .onMapCameraChange(frequency: .onEnd) { context in
                    model.userCoordinate = context.camera.centerCoordinate
                }
                .ignoresSafeArea()

                DiscoverBottomPanel(
                    model: model,
                    searchText: $searchText,
                    selectedVenue: $selectedVenue,
                    isExpanded: $isExpanded
                )
                .frame(height: panelHeight)
                .animation(SparkSprings.sheet, value: isExpanded)
            }
        }
        .sheet(item: $selectedVenue) { venue in
            VenueDetailSheet(venue: venue, model: model)
        }
    }
}

// MARK: - Bottom panel

private struct DiscoverBottomPanel: View {
    var model: DiscoverModel
    @Binding var searchText: String
    @Binding var selectedVenue: Venue?
    @Binding var isExpanded: Bool

    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            grabber
                .padding(.top, 8)
                .padding(.bottom, 6)

            searchField
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            content
        }
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: 28,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: 28,
            style: .continuous
        ))
    }

    private var grabber: some View {
        Capsule()
            .fill(SparkColors.textTertiary.opacity(0.5))
            .frame(width: 40, height: 5)
            .contentShape(Rectangle().inset(by: -16))
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onEnded { value in
                        if value.translation.height < -30 {
                            withAnimation(SparkSprings.sheet) { isExpanded = true }
                        } else if value.translation.height > 30 {
                            withAnimation(SparkSprings.sheet) { isExpanded = false }
                        }
                    }
            )
            .onTapGesture {
                withAnimation(SparkSprings.sheet) { isExpanded.toggle() }
            }
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
                .onChange(of: searchFocused) { _, focused in
                    if focused {
                        withAnimation(SparkSprings.sheet) { isExpanded = true }
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
    }

    @ViewBuilder
    private var content: some View {
        if model.isSearching {
            ProgressView()
                .padding(.top, 12)
            Spacer(minLength: 0)
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
