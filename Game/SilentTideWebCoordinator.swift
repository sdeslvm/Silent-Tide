import Foundation
import WebKit

class SilentTideWebCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
  private let callback: (SilentTideWebStatus) -> Void
  private var didStart = false

  init(onStatus: @escaping (SilentTideWebStatus) -> Void) {
    self.callback = onStatus
  }

  func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    if !didStart { callback(.progressing(progress: 0.0)) }
  }

  func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
    didStart = false
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    callback(.finished)
  }

  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    callback(.failure(reason: error.localizedDescription))
  }

  func webView(
    _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
    withError error: Error
  ) {
    callback(.failure(reason: error.localizedDescription))
  }

  func webView(
    _ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
  ) {
    if navigationAction.navigationType == .other && webView.url != nil {
      didStart = true
    }
    decisionHandler(.allow)
  }

  // MARK: - WKUIDelegate методы для поддержки камеры и микрофона

  func webView(
    _ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin,
    initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType,
    decisionHandler: @escaping (WKPermissionDecision) -> Void
  ) {
    // Автоматически разрешаем доступ к камере и микрофону
    decisionHandler(.grant)
  }

  @available(iOS 15.0, *)
  func webView(
    _ webView: WKWebView,
    requestDeviceOrientationAndMotionPermissionFor origin: WKSecurityOrigin,
    initiatedByFrame frame: WKFrameInfo,
    decisionHandler: @escaping (WKPermissionDecision) -> Void
  ) {
    decisionHandler(.grant)
  }

  func webView(
    _ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
    initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void
  ) {
    completionHandler()
  }

  func webView(
    _ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
    initiatedByFrame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void
  ) {
    completionHandler(true)
  }
}
