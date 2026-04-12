import Foundation
import CoreLocation

final class FakeVenueSearchService: VenueSearchService, @unchecked Sendable {
    var stubbedResults: [Venue] = []
    var stubbedError: SparkError?
    private(set) var lastQuery: String?
    private(set) var lastCoordinate: CLLocationCoordinate2D?

    func search(query: String, near coordinate: CLLocationCoordinate2D) async -> Result<[Venue], SparkError> {
        lastQuery = query
        lastCoordinate = coordinate

        if let error = stubbedError {
            return .failure(error)
        }

        let filtered = stubbedResults.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
        return .success(filtered)
    }
}
