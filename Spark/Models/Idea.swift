import Foundation

struct Idea: Identifiable, Sendable, Equatable, Hashable {
    let id: String
    let title: String
    let category: IdeaCategory
    let createdBy: String
    let createdDate: Date
    let groupIdentifier: String
}
