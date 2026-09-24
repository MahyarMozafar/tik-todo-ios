import UIKit
import UserNotifications

/// Handles reminders: shows them while the app is open, and runs the
/// "Mark as Done" and "Remind Me Later" buttons.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        Reminders.registerActions(language: Preferences.current().language)
        SoundPlayer.shared.prepare()
        return true
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse) async {
        let request = response.notification.request
        if response.actionIdentifier == Reminders.snoozeActionID {
            Reminders.snooze(request.content, id: request.identifier)
            return
        }

        let action = response.actionIdentifier
        let taskID = request.identifier
        await MainActor.run {
            AppModel.shared.handleReminder(action: action, taskID: taskID)
        }
    }
}
