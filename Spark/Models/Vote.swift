import Foundation

struct Vote: Identifiable, Sendable, Equatable {
    let id: String
    let ideaIdentifier: String
    let userIdentifier: String
    let value: Int // +1 or -1
}
