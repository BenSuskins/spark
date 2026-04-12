import Foundation

struct FreeBusySlot: Sendable, Equatable {
    let start: Date
    let end: Date
}

protocol CalendarService: Sendable {
    func requestAccess() async -> Result<Bool, SparkError>
    func freeBusySlots(from start: Date, to end: Date) async -> Result<[FreeBusySlot], SparkError>
    func createEvent(title: String, start: Date, end: Date, notes: String?) async -> Result<String, SparkError>
    func deleteEvent(identifier: String) async -> Result<Void, SparkError>
}
