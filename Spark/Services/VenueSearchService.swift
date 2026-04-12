import Foundation
import MapKit

struct Venue: Identifiable, Sendable, Equatable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let category: String?
    let address: String?

    static func == (lhs: Venue, rhs: Venue) -> Bool {
        lhs.id == rhs.id
            && lhs.name == rhs.name
            && lhs.category == rhs.category
            && lhs.address == rhs.address
    }
}

protocol VenueSearchService: Sendable {
    func search(query: String, near coordinate: CLLocationCoordinate2D) async -> Result<[Venue], SparkError>
}
