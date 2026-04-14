import Foundation

enum SyncStatus: String, Codable, Sendable {
    case pending
    case synced
    case failed
}
