import Foundation
import Observation

@MainActor
@Observable
final class CalendarModel {
    private(set) var hasAccess = false
    private(set) var isOptedIn = false
    private(set) var error: SparkError?

    private let calendarService: CalendarService

    init(calendarService: CalendarService) {
        self.calendarService = calendarService
    }

    func requestAccess() async {
        let result = await calendarService.requestAccess()

        switch result {
        case .success(let granted):
            hasAccess = granted
            isOptedIn = granted
        case .failure(let accessError):
            error = accessError
            hasAccess = false
            isOptedIn = false
        }
    }

    func optOut() {
        isOptedIn = false
    }

    func freeBusySlots(from start: Date, to end: Date) async -> [FreeBusySlot] {
        guard isOptedIn else { return [] }

        let result = await calendarService.freeBusySlots(from: start, to: end)

        if case .success(let slots) = result {
            return slots
        }
        return []
    }

    func createEvent(title: String, start: Date, end: Date, notes: String?) async -> Result<String, SparkError> {
        guard isOptedIn else { return .failure(.calendarAccessDenied) }
        return await calendarService.createEvent(title: title, start: start, end: end, notes: notes)
    }

    func deleteEvent(identifier: String) async -> Result<Void, SparkError> {
        guard isOptedIn else { return .failure(.calendarAccessDenied) }
        return await calendarService.deleteEvent(identifier: identifier)
    }
}
