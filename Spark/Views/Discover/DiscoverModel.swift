import Foundation
import CoreLocation
import Observation

@MainActor
@Observable
final class DiscoverModel {
    private(set) var venues: [Venue] = []
    private(set) var isSearching = false
    private(set) var error: SparkError?

    var userCoordinate: CLLocationCoordinate2D?

    private let venueSearchService: VenueSearchService
    private let dateRepository: DateRepository
    let groupIdentifier: String
    let currentUserIdentifier: String

    init(venueSearchService: VenueSearchService, dateRepository: DateRepository, groupIdentifier: String, currentUserIdentifier: String) {
        self.venueSearchService = venueSearchService
        self.dateRepository = dateRepository
        self.groupIdentifier = groupIdentifier
        self.currentUserIdentifier = currentUserIdentifier
    }

    func search(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            venues = []
            error = nil
            return
        }

        isSearching = true
        error = nil

        let coordinate = userCoordinate ?? CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
        let result = await venueSearchService.search(query: trimmed, near: coordinate)

        switch result {
        case .success(let foundVenues):
            venues = foundVenues
        case .failure(let searchError):
            error = searchError
            venues = []
        }

        isSearching = false
    }

    func addVenueAsIdea(_ venue: Venue, category: IdeaCategory) async -> Result<Idea, SparkError> {
        let idea = Idea(
            id: UUID().uuidString,
            title: venue.name,
            category: category,
            createdBy: currentUserIdentifier,
            createdDate: .now,
            groupIdentifier: groupIdentifier
        )

        return await dateRepository.createIdea(idea, in: groupIdentifier)
    }
}
