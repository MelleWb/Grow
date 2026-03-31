import Foundation
import SwiftUI
import UIKit
import UserNotifications
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

final class PushNotificationManager: NSObject, ObservableObject, MessagingDelegate, UNUserNotificationCenterDelegate {
    static let shared = PushNotificationManager()

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let installationIDKey = "push_notification_installation_id"
    private let trainingReminderNotificationID = "training_reminder_pending_save"
    private var currentUserID: String?

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
    }

    var authorizationStatusDisplayName: String {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "Aan"
        case .denied:
            return "Uit"
        case .notDetermined:
            return "Nog niet gekozen"
        @unknown default:
            return "Onbekend"
        }
    }

    func configure(for userID: String) {
        currentUserID = userID
        refreshAuthorizationStatus()
    }

    func registerForPushNotifications() {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]

        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { [weak self] _, _ in
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
                self?.refreshAuthorizationStatus()
            }
        }
    }

    func refreshAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self else { return }

            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus

                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    UIApplication.shared.registerForRemoteNotifications()
                    self.syncEnabledPushState()
                case .denied:
                    self.syncDisabledPushState()
                case .notDetermined:
                    self.syncDisabledPushState()
                @unknown default:
                    self.syncDisabledPushState()
                }
            }
        }
    }

    func removeCurrentDeviceToken(for userID: String? = nil) {
        guard let resolvedUserID = userID ?? currentUserID else {
            return
        }

        Firestore.firestore()
            .collection("users")
            .document(resolvedUserID)
            .collection("deviceTokens")
            .document(installationID)
            .delete()
    }

    func openNotificationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    func scheduleTrainingReminder(after interval: TimeInterval = 3600) {
        guard authorizationStatus.isEnabledForPush else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Training opslaan"
        content.body = "Vergeet je training van vandaag niet op te slaan"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: trainingReminderNotificationID,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [trainingReminderNotificationID])
        UNUserNotificationCenter.current().add(request)
    }

    func cancelTrainingReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [trainingReminderNotificationID])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [trainingReminderNotificationID])
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        syncEnabledPushState()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }

    private var installationID: String {
        let defaults = UserDefaults.standard

        if let existingValue = defaults.string(forKey: installationIDKey), existingValue.isEmpty == false {
            return existingValue
        }

        let generatedValue = UUID().uuidString
        defaults.set(generatedValue, forKey: installationIDKey)
        return generatedValue
    }

    private func syncEnabledPushState() {
        guard let userID = currentUserID else {
            return
        }

        Messaging.messaging().token { [weak self] token, _ in
            guard let self else { return }

            DispatchQueue.main.async {
                guard let token, token.isEmpty == false else {
                    self.writeDeviceTokenDocument(userID: userID, token: nil)
                    return
                }

                self.writeDeviceTokenDocument(userID: userID, token: token)
            }
        }
    }

    private func syncDisabledPushState() {
        guard let userID = currentUserID else {
            return
        }

        writeDeviceTokenDocument(userID: userID, token: nil)
    }

    private func writeDeviceTokenDocument(userID: String, token: String?) {
        let deviceTokenRef = Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("deviceTokens")
            .document(installationID)

        var payload: [String: Any] = [
            "platform": "iOS",
            "installationID": installationID,
            "authorizationStatus": authorizationStatus.firestoreValue,
            "notificationsEnabled": authorizationStatus.isEnabledForPush,
            "updatedAt": FieldValue.serverTimestamp(),
            "createdAt": FieldValue.serverTimestamp()
        ]

        if let token, token.isEmpty == false {
            payload["token"] = token
        } else {
            payload["token"] = FieldValue.delete()
        }

        deviceTokenRef.setData(payload, merge: true)
    }
}

private extension UNAuthorizationStatus {
    var firestoreValue: String {
        switch self {
        case .authorized:
            return "authorized"
        case .denied:
            return "denied"
        case .notDetermined:
            return "notDetermined"
        case .provisional:
            return "provisional"
        case .ephemeral:
            return "ephemeral"
        @unknown default:
            return "unknown"
        }
    }

    var isEnabledForPush: Bool {
        switch self {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied, .notDetermined:
            return false
        @unknown default:
            return false
        }
    }
}
