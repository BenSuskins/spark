import Foundation

protocol NotificationService: Sendable {
    func requestAuthorization() async -> Result<Bool, SparkError>
    func scheduleJournalPrompt(for plannedDate: PlannedDate) async -> Result<Void, SparkError>
    func scheduleDateReminder(for plannedDate: PlannedDate) async -> Result<Void, SparkError>
    func cancelNotifications(for plannedDateIdentifier: String) async -> Result<Void, SparkError>
}
