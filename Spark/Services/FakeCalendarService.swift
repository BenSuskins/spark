import Foundation

final class FakeCalendarService: CalendarService, @unchecked Sendable {
    var accessGranted = true
    var stubbedSlots: [FreeBusySlot] = []
    private(set) var createdEvents: [(title: String, start: Date, end: Date, notes: String?)] = []
    private(set) var deletedEventIdentifiers: [String] = []
    private var nextEventId = 1

    func requestAccess() async -> Result<Bool, SparkError> {
        .success(accessGranted)
    }

    func freeBusySlots(from start: Date, to end: Date) async -> Result<[FreeBusySlot], SparkError> {
        guard accessGranted else { return .failure(.calendarAccessDenied) }
        let filtered = stubbedSlots.filter { $0.start < end && $0.end > start }
        return .success(filtered)
    }

    func createEvent(title: String, start: Date, end: Date, notes: String?) async -> Result<String, SparkError> {
        guard accessGranted else { return .failure(.calendarAccessDenied) }
        createdEvents.append((title: title, start: start, end: end, notes: notes))
        let identifier = "event-\(nextEventId)"
        nextEventId += 1
        return .success(identifier)
    }

    func deleteEvent(identifier: String) async -> Result<Void, SparkError> {
        guard accessGranted else { return .failure(.calendarAccessDenied) }
        deletedEventIdentifiers.append(identifier)
        return .success(())
    }
}
