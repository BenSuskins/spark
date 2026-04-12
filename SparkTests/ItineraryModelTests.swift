import Testing
import CoreLocation
@testable import Spark

@Test @MainActor func loadItineraryStepsSortedByOrder() async {
    let repository = FakeDateRepository()
    let plannedDate = PlannedDate(id: "d1", title: "Night out", date: .now, status: .planned, groupIdentifier: "g1")
    _ = await repository.createPlannedDate(plannedDate, in: "g1")

    let step2 = ItineraryStep(id: "s2", plannedDateIdentifier: "d1", venueName: "Bar", venueCoordinate: nil, time: .now.addingTimeInterval(7200), notes: "", order: 2)
    let step1 = ItineraryStep(id: "s1", plannedDateIdentifier: "d1", venueName: "Restaurant", venueCoordinate: nil, time: .now, notes: "", order: 1)
    _ = await repository.createItineraryStep(step2, for: plannedDate)
    _ = await repository.createItineraryStep(step1, for: plannedDate)

    let model = ItineraryModel(repository: repository, plannedDate: plannedDate)
    await model.loadSteps()

    #expect(model.steps.count == 2)
    #expect(model.steps.first?.venueName == "Restaurant")
    #expect(model.steps.last?.venueName == "Bar")
}

@Test @MainActor func addItineraryStep() async {
    let repository = FakeDateRepository()
    let plannedDate = PlannedDate(id: "d1", title: "Night out", date: .now, status: .planned, groupIdentifier: "g1")
    _ = await repository.createPlannedDate(plannedDate, in: "g1")

    let model = ItineraryModel(repository: repository, plannedDate: plannedDate)
    await model.addStep(
        venueName: "Cinema",
        venueCoordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1),
        time: .now,
        notes: "IMAX showing"
    )

    #expect(model.steps.count == 1)
    #expect(model.steps.first?.venueName == "Cinema")
    #expect(model.steps.first?.notes == "IMAX showing")
}

@Test @MainActor func deleteItineraryStep() async {
    let repository = FakeDateRepository()
    let plannedDate = PlannedDate(id: "d1", title: "Night out", date: .now, status: .planned, groupIdentifier: "g1")
    _ = await repository.createPlannedDate(plannedDate, in: "g1")

    let model = ItineraryModel(repository: repository, plannedDate: plannedDate)
    await model.addStep(venueName: "Restaurant", venueCoordinate: nil, time: .now, notes: "")

    let step = model.steps.first!
    await model.deleteStep(step)

    #expect(model.steps.isEmpty)
}

@Test @MainActor func promoteIdeaToPlannedDate() async {
    let repository = FakeDateRepository()
    let idea = Idea(id: "idea-1", title: "Sushi night", category: .dining, createdBy: "u1", createdDate: .now, groupIdentifier: "g1")

    let model = HomeModel(repository: repository, currentUserIdentifier: "u1")
    let result = await model.promoteIdeaToDate(idea, date: .now.addingTimeInterval(86400))

    switch result {
    case .success(let plannedDate):
        #expect(plannedDate.title == "Sushi night")
        #expect(plannedDate.status == .planned)
        #expect(plannedDate.groupIdentifier == "g1")
    case .failure:
        Issue.record("Expected success")
    }
}
