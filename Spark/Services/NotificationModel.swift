import Foundation
import Observation

@MainActor
@Observable
final class NotificationModel {
    private(set) var isAuthorized = false
    private(set) var error: SparkError?

    private let notificationService: NotificationService

    init(notificationService: NotificationService) {
        self.notificationService = notificationService
    }

    func requestAuthorization() async {
        let result = await notificationService.requestAuthorization()

        switch result {
        case .success(let granted):
            isAuthorized = granted
        case .failure(let authError):
            error = authError
            isAuthorized = false
        }
    }

    func scheduleDateReminder(for plannedDate: PlannedDate) async {
        guard isAuthorized else { return }
        let result = await notificationService.scheduleDateReminder(for: plannedDate)
        if case .failure(let scheduleError) = result {
            error = scheduleError
        }
    }

    func scheduleJournalPrompt(for plannedDate: PlannedDate) async {
        guard isAuthorized else { return }
        let result = await notificationService.scheduleJournalPrompt(for: plannedDate)
        if case .failure(let scheduleError) = result {
            error = scheduleError
        }
    }

    func cancelNotifications(for plannedDateIdentifier: String) async {
        let result = await notificationService.cancelNotifications(for: plannedDateIdentifier)
        if case .failure(let cancelError) = result {
            error = cancelError
        }
    }
}
