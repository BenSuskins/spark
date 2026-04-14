import Foundation
import SwiftData

@Model
final class PersistedPlannedDate {
    var identifier: String
    var title: String
    var date: Date
    var status: String
    var groupIdentifier: String
    var syncStatus: String

    init(identifier: String, title: String, date: Date, status: String, groupIdentifier: String, syncStatus: SyncStatus = .synced) {
        self.identifier = identifier
        self.title = title
        self.date = date
        self.status = status
        self.groupIdentifier = groupIdentifier
        self.syncStatus = syncStatus.rawValue
    }

    convenience init(from plannedDate: PlannedDate, syncStatus: SyncStatus = .synced) {
        self.init(
            identifier: plannedDate.id,
            title: plannedDate.title,
            date: plannedDate.date,
            status: plannedDate.status.rawValue,
            groupIdentifier: plannedDate.groupIdentifier,
            syncStatus: syncStatus
        )
    }

    func toModel() -> PlannedDate? {
        guard let status = DateStatus(rawValue: status) else { return nil }
        return PlannedDate(id: identifier, title: title, date: date, status: status, groupIdentifier: groupIdentifier)
    }

    func update(from plannedDate: PlannedDate) {
        title = plannedDate.title
        date = plannedDate.date
        status = plannedDate.status.rawValue
        groupIdentifier = plannedDate.groupIdentifier
    }
}
