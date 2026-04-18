import SwiftUI
import MapKit

/// Hero + info + CTA stack for a tapped venue. The hero is a large map snippet
/// (venue photos are not yet modelled). Primary action is "Add to Ideas";
/// secondary opens the venue in Apple Maps.
struct VenueDetailSheet: View {
    let venue: Venue
    let model: DiscoverModel

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: IdeaCategory = .dining
    @State private var addedSuccessfully = false
    @State private var isAdding = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    hero

                    infoCard

                    categoryPicker

                    Spacer(minLength: 8)

                    ctaStack
                }
                .padding(16)
            }
            .background(SparkColors.background)
            .navigationTitle(venue.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Hero

    private var hero: some View {
        Map(
            initialPosition: .region(
                MKCoordinateRegion(
                    center: venue.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            ),
            interactionModes: [.zoom, .pan]
        ) {
            Marker(venue.name, coordinate: venue.coordinate)
                .tint(SparkColors.accent)
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Info

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(venue.name)
                .font(.title2.weight(.bold))
                .foregroundStyle(SparkColors.textPrimary)

            if let category = venue.category {
                Text(category)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SparkColors.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(SparkColors.accentMuted)
                    .clipShape(Capsule())
            }

            if let address = venue.address {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(SparkColors.textSecondary)
                    Text(address)
                        .font(.subheadline)
                        .foregroundStyle(SparkColors.textSecondary)
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .sparkCard(cornerRadius: 20)
    }

    // MARK: - Category picker

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Save to")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SparkColors.textSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(IdeaCategory.allCases) { category in
                        CategoryChip(category: category, isSelected: selectedCategory == category) {
                            withAnimation(SparkSprings.standard) { selectedCategory = category }
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    // MARK: - CTA

    private var ctaStack: some View {
        VStack(spacing: 10) {
            Button {
                Task { await addToIdeas() }
            } label: {
                ZStack {
                    if isAdding {
                        ProgressView().tint(.white)
                    } else if addedSuccessfully {
                        Label("Added to Ideas", systemImage: "checkmark.seal.fill")
                    } else {
                        Label("Add to Ideas", systemImage: "plus")
                    }
                }
            }
            .buttonStyle(SparkPrimaryButtonStyle())
            .disabled(isAdding || addedSuccessfully)

            Button {
                openInMaps()
            } label: {
                Label("Open in Maps", systemImage: "map")
            }
            .buttonStyle(SparkSecondaryButtonStyle())
        }
    }

    // MARK: - Actions

    private func addToIdeas() async {
        isAdding = true
        let result = await model.addVenueAsIdea(venue, category: selectedCategory)
        isAdding = false
        if case .success = result {
            withAnimation(SparkSprings.celebratory) { addedSuccessfully = true }
        }
    }

    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: venue.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = venue.name
        mapItem.openInMaps()
    }
}

private struct CategoryChip: View {
    let category: IdeaCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(category.emoji)
                Text(category.rawValue)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(isSelected ? .white : SparkColors.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? SparkColors.accent : SparkColors.surface)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
