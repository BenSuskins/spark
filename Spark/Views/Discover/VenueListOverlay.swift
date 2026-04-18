import SwiftUI
import MapKit

/// Photo-first venue card used in the half-map Discover sheet. Renders a
/// placeholder map snippet (venue photos aren't yet part of `Venue`), name,
/// category, and address.
struct VenuePhotoCard: View {
    let venue: Venue
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                MapSnippet(coordinate: venue.coordinate)
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(venue.name)
                        .font(.headline)
                        .foregroundStyle(SparkColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let category = venue.category {
                        Text(category)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SparkColors.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(SparkColors.accentMuted)
                            .clipShape(Capsule())
                    }

                    if let address = venue.address {
                        Text(address)
                            .font(.caption)
                            .foregroundStyle(SparkColors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(SparkColors.textTertiary)
                    .padding(.top, 4)
            }
            .padding(12)
            .sparkCard(cornerRadius: 20)
        }
        .buttonStyle(.plain)
    }
}

private struct MapSnippet: View {
    let coordinate: CLLocationCoordinate2D

    var body: some View {
        Map(
            initialPosition: .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
            ),
            interactionModes: []
        ) {
            Marker("", coordinate: coordinate)
                .tint(SparkColors.accent)
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .allowsHitTesting(false)
    }
}
