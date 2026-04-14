import Foundation
import SwiftData

@Model
final class PersistedGroup {
    var identifier: String
    var name: String
    var createdDate: Date
    var ownerIdentifier: String
    var syncStatus: String

    init(identifier: String, name: String, createdDate: Date, ownerIdentifier: String, syncStatus: SyncStatus = .synced) {
        self.identifier = identifier
        self.name = name
        self.createdDate = createdDate
        self.ownerIdentifier = ownerIdentifier
        self.syncStatus = syncStatus.rawValue
    }

    convenience init(from group: Group, syncStatus: SyncStatus = .synced) {
        self.init(
            identifier: group.id,
            name: group.name,
            createdDate: group.createdDate,
            ownerIdentifier: group.ownerIdentifier,
            syncStatus: syncStatus
        )
    }

    func toModel() -> Group {
        Group(id: identifier, name: name, createdDate: createdDate, ownerIdentifier: ownerIdentifier)
    }

    func update(from group: Group) {
        name = group.name
        createdDate = group.createdDate
        ownerIdentifier = group.ownerIdentifier
    }
}
