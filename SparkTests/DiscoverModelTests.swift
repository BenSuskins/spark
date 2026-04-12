import Testing
import CoreLocation
@testable import Spark

@Test @MainActor func searchReturnsMatchingVenues() async {
    let service = FakeVenueSearchService()
    service.stubbedResults = [
        Venue(id: "v1", name: "Sushi Palace", coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1), category: "Restaurant", address: "123 Main St"),
        Venue(id: "v2", name: "Pizza Place", coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1), category: "Restaurant", address: "456 High St"),
        Venue(id: "v3", name: "Central Park", coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1), category: "Park", address: nil),
    ]

    let repository = FakeDateRepository()
    let model = DiscoverModel(venueSearchService: service, dateRepository: repository, groupIdentifier: "g1", currentUserIdentifier: "u1")
    await model.search(query: "Sushi")

    #expect(model.venues.count == 1)
    #expect(model.venues.first?.name == "Sushi Palace")
}

@Test @MainActor func searchWithEmptyQueryClearsResults() async {
    let service = FakeVenueSearchService()
    service.stubbedResults = [
        Venue(id: "v1", name: "Sushi Palace", coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1), category: "Restaurant", address: "123 Main St"),
    ]

    let repository = FakeDateRepository()
    let model = DiscoverModel(venueSearchService: service, dateRepository: repository, groupIdentifier: "g1", currentUserIdentifier: "u1")
    await model.search(query: "Sushi")
    #expect(model.venues.count == 1)

    await model.search(query: "")
    #expect(model.venues.isEmpty)
}

@Test @MainActor func searchErrorSetsErrorState() async {
    let service = FakeVenueSearchService()
    service.stubbedError = .networkUnavailable

    let repository = FakeDateRepository()
    let model = DiscoverModel(venueSearchService: service, dateRepository: repository, groupIdentifier: "g1", currentUserIdentifier: "u1")
    await model.search(query: "anything")

    #expect(model.error == .networkUnavailable)
    #expect(model.venues.isEmpty)
}

@Test @MainActor func addVenueAsIdeaCreatesIdea() async {
    let service = FakeVenueSearchService()
    let repository = FakeDateRepository()
    let model = DiscoverModel(venueSearchService: service, dateRepository: repository, groupIdentifier: "g1", currentUserIdentifier: "u1")

    let venue = Venue(id: "v1", name: "Sushi Palace", coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1), category: "Restaurant", address: "123 Main St")

    let result = await model.addVenueAsIdea(venue, category: .dining)

    switch result {
    case .success(let idea):
        #expect(idea.title == "Sushi Palace")
        #expect(idea.category == .dining)
        #expect(idea.groupIdentifier == "g1")
    case .failure:
        Issue.record("Expected success")
    }

    let ideas = await repository.fetchIdeas(for: "g1")
    if case .success(let allIdeas) = ideas {
        #expect(allIdeas.count == 1)
    }
}

@Test @MainActor func searchPassesCoordinateToService() async {
    let service = FakeVenueSearchService()
    let repository = FakeDateRepository()
    let model = DiscoverModel(venueSearchService: service, dateRepository: repository, groupIdentifier: "g1", currentUserIdentifier: "u1")
    model.userCoordinate = CLLocationCoordinate2D(latitude: 40.7, longitude: -74.0)

    await model.search(query: "coffee")

    #expect(service.lastCoordinate?.latitude == 40.7)
    #expect(service.lastCoordinate?.longitude == -74.0)
}
