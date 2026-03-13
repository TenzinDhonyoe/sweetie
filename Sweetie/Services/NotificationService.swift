import Foundation
import UserNotifications
import UIKit

@MainActor
final class NotificationService: NSObject {
    static let shared = NotificationService()

    private override init() {
        super.init()
    }

    func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge, .timeSensitive]
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
            if granted {
                await registerForRemoteNotifications()
            }
            return granted
        } catch {
            return false
        }
    }

    func registerForRemoteNotifications() async {
        UIApplication.shared.registerForRemoteNotifications()
    }

    func handleDeviceToken(_ deviceToken: Data) -> String {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        return token
    }

    func setupNotificationCategories() {
        let tapCategory = UNNotificationCategory(
            identifier: "TAP",
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let photoCategory = UNNotificationCategory(
            identifier: "PHOTO",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let noteCategory = UNNotificationCategory(
            identifier: "NOTE",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let questionCategory = UNNotificationCategory(
            identifier: "QUESTION",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let partnerJoinedCategory = UNNotificationCategory(
            identifier: "PARTNER_JOINED",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            tapCategory,
            photoCategory,
            noteCategory,
            questionCategory,
            partnerJoinedCategory
        ])
    }
}
