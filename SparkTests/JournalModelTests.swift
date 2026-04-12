import Testing
@testable import Spark

@Test @MainActor func createJournalEntryForPlannedDate() async {
    let repository = FakeDateRepository()
    let plannedDate = PlannedDate(id: "d1", title: "Dinner", date: .now.addingTimeInterval(-86400), status: .completed, groupIdentifier: "g1")
    _ = await repository.createPlannedDate(plannedDate, in: "g1")

    let model = JournalModel(repository: repository, plannedDate: plannedDate)
    await model.saveEntry(rating: 4, notes: "Great evening!")

    #expect(model.entry != nil)
    #expect(model.entry?.rating == 4)
    #expect(model.entry?.notes == "Great evening!")
    #expect(model.entry?.plannedDateIdentifier == "d1")
}

@Test @MainActor func loadExistingJournalEntry() async {
    let repository = FakeDateRepository()
    let plannedDate = PlannedDate(id: "d1", title: "Dinner", date: .now.addingTimeInterval(-86400), status: .completed, groupIdentifier: "g1")
    _ = await repository.createPlannedDate(plannedDate, in: "g1")

    let entry = JournalEntry(id: "j1", plannedDateIdentifier: "d1", rating: 5, notes: "Perfect", createdDate: .now)
    _ = await repository.createJournalEntry(entry, for: plannedDate)

    let model = JournalModel(repository: repository, plannedDate: plannedDate)
    await model.loadEntry()

    #expect(model.entry != nil)
    #expect(model.entry?.rating == 5)
    #expect(model.entry?.notes == "Perfect")
}

@Test @MainActor func updateExistingJournalEntry() async {
    let repository = FakeDateRepository()
    let plannedDate = PlannedDate(id: "d1", title: "Dinner", date: .now.addingTimeInterval(-86400), status: .completed, groupIdentifier: "g1")
    _ = await repository.createPlannedDate(plannedDate, in: "g1")

    let model = JournalModel(repository: repository, plannedDate: plannedDate)
    await model.saveEntry(rating: 3, notes: "It was okay")

    #expect(model.entry?.rating == 3)

    await model.saveEntry(rating: 5, notes: "Actually it was amazing")

    #expect(model.entry?.rating == 5)
    #expect(model.entry?.notes == "Actually it was amazing")
}

@Test @MainActor func journalEntryHasNoEntryInitially() async {
    let repository = FakeDateRepository()
    let plannedDate = PlannedDate(id: "d1", title: "Dinner", date: .now, status: .planned, groupIdentifier: "g1")
    _ = await repository.createPlannedDate(plannedDate, in: "g1")

    let model = JournalModel(repository: repository, plannedDate: plannedDate)
    await model.loadEntry()

    #expect(model.entry == nil)
    #expect(model.hasEntry == false)
}

@Test @MainActor func ratingClampedBetween1And5() async {
    let repository = FakeDateRepository()
    let plannedDate = PlannedDate(id: "d1", title: "Dinner", date: .now, status: .completed, groupIdentifier: "g1")
    _ = await repository.createPlannedDate(plannedDate, in: "g1")

    let model = JournalModel(repository: repository, plannedDate: plannedDate)

    await model.saveEntry(rating: 0, notes: "")
    #expect(model.entry?.rating == 1)

    await model.saveEntry(rating: 10, notes: "")
    #expect(model.entry?.rating == 5)
}
