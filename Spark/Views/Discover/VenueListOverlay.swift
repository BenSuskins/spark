import SwiftUI

struct VenueListOverlay: View {
    let venues: [Venue]
    @Binding var selectedVenue: Venue?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(venues) { venue in
                    VenueChip(venue: venue, isSelected: selectedVenue?.id == venue.id)
                        .onTapGesture {
                            selectedVenue = venue
                        }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

struct VenueChip: View {
    let venue: Venue
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(venue.name)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)

            if let category = venue.category {
                Text(category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
