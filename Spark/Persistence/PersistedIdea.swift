import Foundation
import SwiftData

@Model
final class PersistedIdea {
    var identifier: String
    var title: String
    var category: String
    var createdBy: String
    var createdDate: Date
    var groupIdentifier: String
    var isPlanned: Bool
    var syncStatus: String

    init(identifier: String, title: String, category: String, createdBy: String, createdDate: Date, groupIdentifier: String, isPlanned: Bool, syncStatus: SyncStatus = .synced) {
        self.identifier = identifier
        self.title = title
        self.category = category
        self.createdBy = createdBy
        self.createdDate = createdDate
        self.groupIdentifier = groupIdentifier
        self.isPlanned = isPlanned
        self.syncStatus = syncStatus.rawValue
    }

    convenience init(from idea: Idea, syncStatus: SyncStatus = .synced) {
        self.init(
            identifier: idea.id,
            title: idea.title,
            category: idea.category.rawValue,
            createdBy: idea.createdBy,
            createdDate: idea.createdDate,
            groupIdentifier: idea.groupIdentifier,
            isPlanned: idea.isPlanned,
            syncStatus: syncStatus
        )
    }

    func toModel() -> Idea? {
        guard let category = IdeaCategory(rawValue: category) else { return nil }
        return Idea(
            id: identifier,
            title: title,
            category: category,
            createdBy: createdBy,
            createdDate: createdDate,
            groupIdentifier: groupIdentifier,
            isPlanned: isPlanned
        )
    }

    func update(from idea: Idea) {
        title = idea.title
        category = idea.category.rawValue
        createdBy = idea.createdBy
        createdDate = idea.createdDate
        groupIdentifier = idea.groupIdentifier
        isPlanned = idea.isPlanned
    }
}
