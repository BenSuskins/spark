import Foundation

struct Group: Identifiable, Sendable, Equatable {
    let id: String
    let name: String
    let emoji: String
    let createdDate: Date
    let ownerIdentifier: String

    init(
        id: String,
        name: String,
        emoji: String = "💞",
        createdDate: Date,
        ownerIdentifier: String
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.createdDate = createdDate
        self.ownerIdentifier = ownerIdentifier
    }
}
