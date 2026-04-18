import Foundation
import SwiftData

@Model
final class PersistedGroup {
    var identifier: String
    var name: String
    var emoji: String?
    var createdDate: Date
    var ownerIdentifier: String
    var syncStatus: String

    init(
        identifier: String,
        name: String,
        emoji: String = "💞",
        createdDate: Date,
        ownerIdentifier: String,
        syncStatus: SyncStatus = .synced
    ) {
        self.identifier = identifier
        self.name = name
        self.emoji = emoji
        self.createdDate = createdDate
        self.ownerIdentifier = ownerIdentifier
        self.syncStatus = syncStatus.rawValue
    }

    convenience init(from group: Group, syncStatus: SyncStatus = .synced) {
        self.init(
            identifier: group.id,
            name: group.name,
            emoji: group.emoji,
            createdDate: group.createdDate,
            ownerIdentifier: group.ownerIdentifier,
            syncStatus: syncStatus
        )
    }

    func toModel() -> Group {
        Group(
            id: identifier,
            name: name,
            emoji: emoji ?? "💞",
            createdDate: createdDate,
            ownerIdentifier: ownerIdentifier
        )
    }

    func update(from group: Group) {
        name = group.name
        emoji = group.emoji
        createdDate = group.createdDate
        ownerIdentifier = group.ownerIdentifier
    }
}
