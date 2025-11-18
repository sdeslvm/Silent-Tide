import FirebaseCore
import FirebaseMessaging
import OSLog
import UIKit
import UserNotifications

/// Handles push notification registration, permission prompts, and FCM token lifecycle.
final class FCMManager: NSObject {
  static let shared = FCMManager()
  private static let tokenDefaultsKey = "fcm_token"

  private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Push", category: "FCM")
  private let notificationCenter = UNUserNotificationCenter.current()
  private let defaults = UserDefaults.standard

  private override init() {
    super.init()
  }

  func configureMessaging() {
    notificationCenter.delegate = self
    Messaging.messaging().delegate = self
    requestAuthorization()
  }

  private func requestAuthorization() {
    notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
      if let error {
        self?.logger.error("Push permission request failed: \(error.localizedDescription)")
        return
      }

      self?.logger.info("Push permission granted: \(granted, privacy: .public)")
      guard granted else { return }
      DispatchQueue.main.async {
        UIApplication.shared.registerForRemoteNotifications()
      }
    }
  }

  private func persist(token: String) {
    logger.debug("🔥 FCM Token received: \(token, privacy: .public)")
    defaults.set(token, forKey: Self.tokenDefaultsKey)
    NotificationCenter.default.post(
      name: .fcmTokenDidUpdate,
      object: nil,
      userInfo: [NotificationCenter.fcmTokenKey: token]
    )
  }

  static func cachedToken() -> String? {
    UserDefaults.standard.string(forKey: tokenDefaultsKey)
  }
}

extension FCMManager: UNUserNotificationCenterDelegate {
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .badge, .sound])
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    completionHandler()
  }
}

extension FCMManager: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    guard let token = fcmToken else { return }
    persist(token: token)
  }
}

extension Notification.Name {
  static let fcmTokenDidUpdate = Notification.Name("FCMTokenDidUpdate")
}

extension NotificationCenter {
  static let fcmTokenKey = "token"
}
