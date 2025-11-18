import UIKit
import WebKit

/// Hosts the web view and locks orientation until JavaScript explicitly unlocks it.
final class SilentTideBaseWebViewController: UIViewController, WKScriptMessageHandler {
  private enum Constants {
    static let orientationMessageName = "orientation"
    static let callbackMessageName = "jsHandler"
    static let unlockToken = "ok"
  }

  let defaultOrientations: UIInterfaceOrientationMask
  private let loader: SilentTideWebLoader
  private let coordinator: SilentTideWebCoordinator
  private let configuration: WKWebViewConfiguration
  private var orientationUnlocked = false

  private(set) lazy var webView: WKWebView = WKWebView(frame: .zero, configuration: configuration)
  private let containerView = GradientContainerView()

  init(
    defaultOrientations: UIInterfaceOrientationMask,
    loader: SilentTideWebLoader,
    coordinator: SilentTideWebCoordinator,
    configuration: WKWebViewConfiguration
  ) {
    self.defaultOrientations = defaultOrientations
    self.loader = loader
    self.coordinator = coordinator
    self.configuration = configuration
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    SilentTideOrientationManager.shared.updateAllowedOrientations(defaultOrientations)

    configuration.userContentController.add(self, name: Constants.orientationMessageName)
    configuration.userContentController.add(self, name: Constants.callbackMessageName)

    webView.navigationDelegate = coordinator
    webView.uiDelegate = coordinator
    configureWebViewAppearance()

    containerView.addSubview(webView)
    webView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      webView.topAnchor.constraint(equalTo: containerView.topAnchor),
      webView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
    ])

    view = containerView

    loader.attachWebView { [weak self] in
      guard let self else { return WKWebView(frame: .zero) }
      return self.webView
    }
  }

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    SilentTideOrientationManager.shared.currentMask
  }

  deinit {
    configuration.userContentController.removeScriptMessageHandler(
      forName: Constants.orientationMessageName)
    configuration.userContentController.removeScriptMessageHandler(
      forName: Constants.callbackMessageName)
  }

  private func configureWebViewAppearance() {
    webView.isOpaque = false
    webView.scrollView.bounces = false
    webView.scrollView.isScrollEnabled = true
    webView.allowsBackForwardNavigationGestures = true
    webView.configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
    webView.configuration.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
  }

  private func unlockOrientationIfNeeded() {
    guard !orientationUnlocked else { return }
    orientationUnlocked = true
    SilentTideOrientationManager.shared.updateAllowedOrientations(.all)
  }

  // MARK: - WKScriptMessageHandler

  func userContentController(
    _ userContentController: WKUserContentController, didReceive message: WKScriptMessage
  ) {
    switch message.name {
    case Constants.orientationMessageName:
      handleOrientationMessage(message)
    case Constants.callbackMessageName:
      handleCallbackMessage(message)
    default:
      break
    }
  }
}

extension SilentTideBaseWebViewController {
  fileprivate func handleOrientationMessage(_ message: WKScriptMessage) {
    if let string = message.body as? String, string.lowercased() == Constants.unlockToken {
      unlockOrientationIfNeeded()
      return
    }

    if let dict = message.body as? [String: Any],
      let status = dict["status"] as? String,
      status.lowercased() == Constants.unlockToken
    {
      unlockOrientationIfNeeded()
    }
  }

  fileprivate func handleCallbackMessage(_ message: WKScriptMessage) {
    if let body = message.body as? String {
      print("Received callback message: \(body)")
      if body.lowercased() == Constants.unlockToken {
        unlockOrientationIfNeeded()
      }
      return
    }

    if let body = message.body as? [String: Any] {
      print("Received callback message: \(body)")
      if let status = body["status"] as? String, status.lowercased() == Constants.unlockToken {
        unlockOrientationIfNeeded()
      }
      return
    }

    print("Received callback message: \(String(describing: message.body))")
  }
}
