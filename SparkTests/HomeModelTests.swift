import Testing
@testable import Spark

@Test @MainActor func loadUpcomingDatesForGroup() async {
    let repository = FakeDateRepository()
    let future = PlannedDate(id: "d1", title: "Dinner", date: .now.addingTimeInterval(86400), status: .planned, groupIdentifier: "g1")
    let past = PlannedDate(id: "d2", title: "Old date", date: .now.addingTimeInterval(-86400), status: .completed, groupIdentifier: "g1")
    _ = await repository.createPlannedDate(future, in: "g1")
    _ = await repository.createPlannedDate(past, in: "g1")

    let model = HomeModel(repository: repository, currentUserIdentifier: "u1")
    model.selectedGroupIdentifier = "g1"
    await model.loadDates(for: ["g1"])

    #expect(model.upcomingDates.count == 1)
    #expect(model.upcomingDates.first?.title == "Dinner")
}

@Test @MainActor func loadPastDatesForGroup() async {
    let repository = FakeDateRepository()
    let past = PlannedDate(id: "d1", title: "Beach day", date: .now.addingTimeInterval(-86400), status: .completed, groupIdentifier: "g1")
    _ = await repository.createPlannedDate(past, in: "g1")

    let model = HomeModel(repository: repository, currentUserIdentifier: "u1")
    model.selectedGroupIdentifier = "g1"
    await model.loadDates(for: ["g1"])

    #expect(model.pastDates.count == 1)
    #expect(model.pastDates.first?.title == "Beach day")
}

@Test @MainActor func loadAllGroupsAggregatesDates() async {
    let repository = FakeDateRepository()
    let date1 = PlannedDate(id: "d1", title: "Group 1 date", date: .now.addingTimeInterval(86400), status: .planned, groupIdentifier: "g1")
    let date2 = PlannedDate(id: "d2", title: "Group 2 date", date: .now.addingTimeInterval(172800), status: .planned, groupIdentifier: "g2")
    _ = await repository.createPlannedDate(date1, in: "g1")
    _ = await repository.createPlannedDate(date2, in: "g2")

    let model = HomeModel(repository: repository, currentUserIdentifier: "u1")
    model.selectedGroupIdentifier = nil // All Groups
    await model.loadDates(for: ["g1", "g2"])

    #expect(model.upcomingDates.count == 2)
}

@Test @MainActor func upcomingDatesSortedByDateAscending() async {
    let repository = FakeDateRepository()
    let later = PlannedDate(id: "d1", title: "Later", date: .now.addingTimeInterval(172800), status: .planned, groupIdentifier: "g1")
    let sooner = PlannedDate(id: "d2", title: "Sooner", date: .now.addingTimeInterval(86400), status: .planned, groupIdentifier: "g1")
    _ = await repository.createPlannedDate(later, in: "g1")
    _ = await repository.createPlannedDate(sooner, in: "g1")

    let model = HomeModel(repository: repository, currentUserIdentifier: "u1")
    model.selectedGroupIdentifier = "g1"
    await model.loadDates(for: ["g1"])

    #expect(model.upcomingDates.first?.title == "Sooner")
    #expect(model.upcomingDates.last?.title == "Later")
}
