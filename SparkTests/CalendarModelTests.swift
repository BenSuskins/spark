import Testing
import Foundation
@testable import Spark

@Test @MainActor func requestCalendarAccessGranted() async {
    let service = FakeCalendarService()
    let model = CalendarModel(calendarService: service)

    await model.requestAccess()

    #expect(model.hasAccess == true)
    #expect(model.isOptedIn == true)
}

@Test @MainActor func requestCalendarAccessDenied() async {
    let service = FakeCalendarService()
    service.accessGranted = false
    let model = CalendarModel(calendarService: service)

    await model.requestAccess()

    #expect(model.hasAccess == false)
    #expect(model.isOptedIn == false)
}

@Test @MainActor func optOutClearsAccess() async {
    let service = FakeCalendarService()
    let model = CalendarModel(calendarService: service)

    await model.requestAccess()
    #expect(model.isOptedIn == true)

    model.optOut()
    #expect(model.isOptedIn == false)
}

@Test @MainActor func fetchFreeBusySlotsReturnsFiltered() async {
    let service = FakeCalendarService()
    let now = Date.now
    service.stubbedSlots = [
        FreeBusySlot(start: now.addingTimeInterval(3600), end: now.addingTimeInterval(7200)),
        FreeBusySlot(start: now.addingTimeInterval(86400), end: now.addingTimeInterval(90000)),
    ]
    let model = CalendarModel(calendarService: service)
    await model.requestAccess()

    let slots = await model.freeBusySlots(from: now, to: now.addingTimeInterval(10000))

    #expect(slots.count == 1)
}

@Test @MainActor func createEventForPlannedDate() async {
    let service = FakeCalendarService()
    let model = CalendarModel(calendarService: service)
    await model.requestAccess()

    let start = Date.now.addingTimeInterval(86400)
    let end = start.addingTimeInterval(7200)

    let result = await model.createEvent(title: "Dinner", start: start, end: end, notes: "Sushi place")

    switch result {
    case .success(let identifier):
        #expect(identifier.hasPrefix("event-"))
        #expect(service.createdEvents.count == 1)
        #expect(service.createdEvents.first?.title == "Dinner")
    case .failure:
        Issue.record("Expected success")
    }
}

@Test @MainActor func createEventWhenNotOptedInFails() async {
    let service = FakeCalendarService()
    let model = CalendarModel(calendarService: service)

    let result = await model.createEvent(title: "Dinner", start: .now, end: .now, notes: nil)

    switch result {
    case .success:
        Issue.record("Expected failure")
    case .failure(let error):
        #expect(error == .calendarAccessDenied)
    }
}
