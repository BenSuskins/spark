import Foundation
import MapKit

final class MapKitVenueSearchService: VenueSearchService {
    func search(query: String, near coordinate: CLLocationCoordinate2D) async -> Result<[Venue], SparkError> {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 5000,
            longitudinalMeters: 5000
        )

        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()
            let venues = response.mapItems.compactMap { item -> Venue? in
                guard let name = item.name else { return nil }
                let placemark = item.placemark
                return Venue(
                    id: "\(placemark.coordinate.latitude),\(placemark.coordinate.longitude)" + name,
                    name: name,
                    coordinate: placemark.coordinate,
                    category: item.pointOfInterestCategory?.rawValue,
                    address: formatAddress(placemark)
                )
            }
            return .success(venues)
        } catch {
            return .failure(.cloudKitError(error.localizedDescription))
        }
    }

    private func formatAddress(_ placemark: MKPlacemark) -> String? {
        let components = [
            placemark.subThoroughfare,
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea,
            placemark.postalCode
        ].compactMap { $0 }

        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}
