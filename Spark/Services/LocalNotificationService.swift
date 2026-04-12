import Foundation
import UserNotifications

final class LocalNotificationService: NotificationService, @unchecked Sendable {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Result<Bool, SparkError> {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return .success(granted)
        } catch {
            return .failure(.permissionDenied)
        }
    }

    func scheduleDateReminder(for plannedDate: PlannedDate) async -> Result<Void, SparkError> {
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Date"
        content.body = "\(plannedDate.title) is tomorrow!"
        content.sound = .default

        let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: plannedDate.date) ?? plannedDate.date
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "reminder-\(plannedDate.id)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            return .success(())
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func scheduleJournalPrompt(for plannedDate: PlannedDate) async -> Result<Void, SparkError> {
        let content = UNMutableNotificationContent()
        content.title = "How was your date?"
        content.body = "Tell us about \(plannedDate.title)!"
        content.sound = .default

        let promptDate = Calendar.current.date(byAdding: .day, value: 1, to: plannedDate.date) ?? plannedDate.date
        let morning = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: promptDate) ?? promptDate
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: morning)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "journal-\(plannedDate.id)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            return .success(())
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }

    func cancelNotifications(for plannedDateIdentifier: String) async -> Result<Void, SparkError> {
        center.removePendingNotificationRequests(withIdentifiers: [
            "reminder-\(plannedDateIdentifier)",
            "journal-\(plannedDateIdentifier)"
        ])
        return .success(())
    }
}
