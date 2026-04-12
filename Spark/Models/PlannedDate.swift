import Foundation

enum DateStatus: String, Codable, Sendable {
    case planned
    case completed
}

struct PlannedDate: Identifiable, Sendable, Equatable, Hashable {
    let id: String
    let title: String
    let date: Date
    let status: DateStatus
    let groupIdentifier: String
}
