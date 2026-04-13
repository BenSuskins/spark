import SwiftUI
import CloudKit

@main
struct SparkApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - AppDelegate

final class AppDelegate: NSObject, UIApplicationDelegate {
    /// Called by iOS when the user accepts a CloudKit share invite (e.g. taps an invite link).
    /// The system presents its own confirmation UI before this fires, so by the time we reach
    /// here the user has already agreed to join.
    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        Task {
            let container = CKContainer(identifier: CloudKitManager.containerIdentifier)
            try? await container.accept(cloudKitShareMetadata)
            // Notify ContentView so it reloads the group list and picks up the accepted share.
            await MainActor.run {
                NotificationCenter.default.post(name: .cloudKitShareAccepted, object: nil)
            }
        }
    }
}

extension Notification.Name {
    static let cloudKitShareAccepted = Notification.Name("cloudKitShareAccepted")
}
