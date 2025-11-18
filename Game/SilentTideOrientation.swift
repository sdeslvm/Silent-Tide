import FirebaseCore
import FirebaseMessaging
import OSLog
import UIKit

/// Manages the current orientation mask for the application window scenes.
final class SilentTideOrientationManager {
  static let shared = SilentTideOrientationManager()

  private init() {}

  private(set) var currentMask: UIInterfaceOrientationMask = .allButUpsideDown

  func updateAllowedOrientations(_ mask: UIInterfaceOrientationMask) {
    DispatchQueue.main.async {
      guard self.currentMask != mask else { return }
      self.currentMask = mask

      UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .forEach { $0.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations() }

      UIViewController.attemptRotationToDeviceOrientation()
    }
  }
}

/// App delegate bridge so SwiftUI asks us for the current orientation mask.
final class SilentTideAppDelegate: NSObject, UIApplicationDelegate {
  private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Push", category: "AppDelegate")

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    FCMManager.shared.configureMessaging()
    logger.info("Push notifications configured")
    return true
  }

  func application(
    _ application: UIApplication,
    supportedInterfaceOrientationsFor window: UIWindow?
  ) -> UIInterfaceOrientationMask {
    SilentTideOrientationManager.shared.currentMask
  }

  func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    logger.info("APNs token registered")
  }

  func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: any Error
  ) {
    logger.error("APNs registration failed: \(error.localizedDescription, privacy: .public)")
  }
}
