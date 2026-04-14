import Foundation
import SwiftData

@Model
final class PersistedJournalEntry {
    var identifier: String
    var plannedDateIdentifier: String
    var rating: Int
    var notes: String
    var createdDate: Date
    var groupIdentifier: String
    var syncStatus: String

    init(identifier: String, plannedDateIdentifier: String, rating: Int, notes: String, createdDate: Date, groupIdentifier: String, syncStatus: SyncStatus = .synced) {
        self.identifier = identifier
        self.plannedDateIdentifier = plannedDateIdentifier
        self.rating = rating
        self.notes = notes
        self.createdDate = createdDate
        self.groupIdentifier = groupIdentifier
        self.syncStatus = syncStatus.rawValue
    }

    convenience init(from entry: JournalEntry, groupIdentifier: String, syncStatus: SyncStatus = .synced) {
        self.init(
            identifier: entry.id,
            plannedDateIdentifier: entry.plannedDateIdentifier,
            rating: entry.rating,
            notes: entry.notes,
            createdDate: entry.createdDate,
            groupIdentifier: groupIdentifier,
            syncStatus: syncStatus
        )
    }

    func toModel() -> JournalEntry {
        JournalEntry(id: identifier, plannedDateIdentifier: plannedDateIdentifier, rating: rating, notes: notes, createdDate: createdDate)
    }

    func update(from entry: JournalEntry) {
        plannedDateIdentifier = entry.plannedDateIdentifier
        rating = entry.rating
        notes = entry.notes
        createdDate = entry.createdDate
    }
}
