import Foundation

struct Group: Identifiable, Sendable, Equatable {
    let id: String
    let name: String
    let createdDate: Date
    let ownerIdentifier: String
}
