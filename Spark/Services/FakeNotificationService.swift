import Foundation

final class FakeNotificationService: NotificationService, @unchecked Sendable {
    var authorizationGranted = true
    private(set) var scheduledJournalPrompts: [String] = []
    private(set) var scheduledDateReminders: [String] = []
    private(set) var cancelledIdentifiers: [String] = []

    func requestAuthorization() async -> Result<Bool, SparkError> {
        .success(authorizationGranted)
    }

    func scheduleJournalPrompt(for plannedDate: PlannedDate) async -> Result<Void, SparkError> {
        guard authorizationGranted else { return .failure(.permissionDenied) }
        scheduledJournalPrompts.append(plannedDate.id)
        return .success(())
    }

    func scheduleDateReminder(for plannedDate: PlannedDate) async -> Result<Void, SparkError> {
        guard authorizationGranted else { return .failure(.permissionDenied) }
        scheduledDateReminders.append(plannedDate.id)
        return .success(())
    }

    func cancelNotifications(for plannedDateIdentifier: String) async -> Result<Void, SparkError> {
        cancelledIdentifiers.append(plannedDateIdentifier)
        return .success(())
    }
}
