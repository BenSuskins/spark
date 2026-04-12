import Foundation

enum SparkError: Error, Sendable, Equatable {
    case networkUnavailable
    case notAuthenticated
    case recordNotFound
    case permissionDenied
    case cloudKitError(String)
    case calendarAccessDenied
    case unknown(String)
}
