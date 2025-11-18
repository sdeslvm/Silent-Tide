import Foundation
import UserNotifications

/// Handles mutable push content to attach remote-rich media (images, etc.).
final class NotificationService: UNNotificationServiceExtension {
  private var contentHandler: ((UNNotificationContent) -> Void)?
  private var bestAttemptContent: UNMutableNotificationContent?

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    self.contentHandler = contentHandler
    bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

    guard let bestAttemptContent else {
      contentHandler(request.content)
      return
    }

    guard let attachmentURL = request.content.userInfo["image"] as? String,
          let url = URL(string: attachmentURL) else {
      contentHandler(bestAttemptContent)
      return
    }

    downloadImage(from: url) { [weak self] attachment in
      if let attachment {
        bestAttemptContent.attachments = [attachment]
      }
      self?.contentHandler?(bestAttemptContent)
    }
  }

  override func serviceExtensionTimeWillExpire() {
    if let contentHandler, let bestAttemptContent {
      contentHandler(bestAttemptContent)
    }
  }

  private func downloadImage(from url: URL, completion: @escaping (UNNotificationAttachment?) -> Void) {
    URLSession.shared.downloadTask(with: url) { location, _, _ in
      guard let location else {
        completion(nil)
        return
      }

      let tmpDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
      let fileURL = tmpDirectory.appendingPathComponent(UUID().uuidString + ".jpg")

      do {
        try FileManager.default.moveItem(at: location, to: fileURL)
        let attachment = try UNNotificationAttachment(identifier: "image", url: fileURL, options: nil)
        completion(attachment)
      } catch {
        completion(nil)
      }
    }.resume()
  }
}
