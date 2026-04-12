import Testing
import Foundation
@testable import Spark

@Test @MainActor func requestNotificationAuthorizationGranted() async {
    let service = FakeNotificationService()
    let model = NotificationModel(notificationService: service)

    await model.requestAuthorization()

    #expect(model.isAuthorized == true)
}

@Test @MainActor func requestNotificationAuthorizationDenied() async {
    let service = FakeNotificationService()
    service.authorizationGranted = false
    let model = NotificationModel(notificationService: service)

    await model.requestAuthorization()

    #expect(model.isAuthorized == false)
}

@Test @MainActor func scheduleDateReminderWhenAuthorized() async {
    let service = FakeNotificationService()
    let model = NotificationModel(notificationService: service)
    await model.requestAuthorization()

    let plannedDate = PlannedDate(
        id: "date-1",
        title: "Dinner",
        date: Date.now.addingTimeInterval(86400),
        status: .planned,
        groupIdentifier: "group-1"
    )

    await model.scheduleDateReminder(for: plannedDate)

    #expect(service.scheduledDateReminders == ["date-1"])
}

@Test @MainActor func scheduleDateReminderSkippedWhenNotAuthorized() async {
    let service = FakeNotificationService()
    let model = NotificationModel(notificationService: service)

    let plannedDate = PlannedDate(
        id: "date-1",
        title: "Dinner",
        date: Date.now.addingTimeInterval(86400),
        status: .planned,
        groupIdentifier: "group-1"
    )

    await model.scheduleDateReminder(for: plannedDate)

    #expect(service.scheduledDateReminders.isEmpty)
}

@Test @MainActor func scheduleJournalPromptWhenAuthorized() async {
    let service = FakeNotificationService()
    let model = NotificationModel(notificationService: service)
    await model.requestAuthorization()

    let plannedDate = PlannedDate(
        id: "date-1",
        title: "Dinner",
        date: Date.now,
        status: .completed,
        groupIdentifier: "group-1"
    )

    await model.scheduleJournalPrompt(for: plannedDate)

    #expect(service.scheduledJournalPrompts == ["date-1"])
}

@Test @MainActor func cancelNotificationsRemovesScheduled() async {
    let service = FakeNotificationService()
    let model = NotificationModel(notificationService: service)
    await model.requestAuthorization()

    await model.cancelNotifications(for: "date-1")

    #expect(service.cancelledIdentifiers == ["date-1"])
}
