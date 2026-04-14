import Foundation
import SwiftData

@Model
final class PersistedVote {
    var identifier: String
    var ideaIdentifier: String
    var userIdentifier: String
    var value: Int
    var groupIdentifier: String
    var syncStatus: String

    init(identifier: String, ideaIdentifier: String, userIdentifier: String, value: Int, groupIdentifier: String, syncStatus: SyncStatus = .synced) {
        self.identifier = identifier
        self.ideaIdentifier = ideaIdentifier
        self.userIdentifier = userIdentifier
        self.value = value
        self.groupIdentifier = groupIdentifier
        self.syncStatus = syncStatus.rawValue
    }

    convenience init(from vote: Vote, groupIdentifier: String, syncStatus: SyncStatus = .synced) {
        self.init(
            identifier: vote.id,
            ideaIdentifier: vote.ideaIdentifier,
            userIdentifier: vote.userIdentifier,
            value: vote.value,
            groupIdentifier: groupIdentifier,
            syncStatus: syncStatus
        )
    }

    func toModel() -> Vote {
        Vote(id: identifier, ideaIdentifier: ideaIdentifier, userIdentifier: userIdentifier, value: value)
    }

    func update(from vote: Vote) {
        ideaIdentifier = vote.ideaIdentifier
        userIdentifier = vote.userIdentifier
        value = vote.value
    }
}
