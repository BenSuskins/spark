import Foundation
import EventKit

final class EventKitCalendarService: CalendarService, @unchecked Sendable {
    private let store = EKEventStore()

    func requestAccess() async -> Result<Bool, SparkError> {
        do {
            let granted = try await store.requestFullAccessToEvents()
            return .success(granted)
        } catch {
            return .failure(.calendarAccessDenied)
        }
    }

    func freeBusySlots(from start: Date, to end: Date) async -> Result<[FreeBusySlot], SparkError> {
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let events = store.events(matching: predicate)

        let slots = events.map { FreeBusySlot(start: $0.startDate, end: $0.endDate) }
        return .success(slots)
    }

    func createEvent(title: String, start: Date, end: Date, notes: String?) async -> Result<String, SparkError> {
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = start
        event.endDate = end
        event.notes = notes
        event.calendar = store.defaultCalendarForNewEvents

        do {
            try store.save(event, span: .thisEvent)
            return .success(event.eventIdentifier)
        } catch {
            return .failure(.cloudKitError(error.localizedDescription))
        }
    }

    func deleteEvent(identifier: String) async -> Result<Void, SparkError> {
        guard let event = store.event(withIdentifier: identifier) else {
            return .failure(.recordNotFound)
        }

        do {
            try store.remove(event, span: .thisEvent)
            return .success(())
        } catch {
            return .failure(.cloudKitError(error.localizedDescription))
        }
    }
}
