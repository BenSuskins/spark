import Foundation

struct JournalEntry: Identifiable, Sendable, Equatable {
    let id: String
    let plannedDateIdentifier: String
    let rating: Int // 1-5
    let notes: String
    let createdDate: Date
}
