import Foundation

enum SparkError: Error, Sendable, Equatable {
    case networkUnavailable
    case notAuthenticated
    case recordNotFound
    case permissionDenied
    case cloudKitError(String)
    case calendarAccessDenied
    case unknown(String)

    var localizedDescription: String {
        switch self {
        case .networkUnavailable:
            return "No network connection. Please check your connection and try again."
        case .notAuthenticated:
            return "Please sign in to iCloud in Settings to use this feature."
        case .recordNotFound:
            return "The requested record could not be found."
        case .permissionDenied:
            return "Permission denied. Please check your iCloud settings."
        case .cloudKitError(let message):
            return message
        case .calendarAccessDenied:
            return "Calendar access denied. Please allow access in Settings."
        case .unknown(let message):
            return message
        }
    }
}
