import Combine
import SwiftUI
import WebKit

// MARK: - Протоколы

/// Протокол для управления состоянием веб-загрузки
protocol WebLoadable: AnyObject {
  var state: SilentTideWebStatus { get set }
  func setConnectivity(_ available: Bool)
}

/// Протокол для мониторинга прогресса загрузки
protocol ProgressMonitoring {
  func observeProgression()
  func monitor(_ webView: WKWebView)
}

// MARK: - Основной загрузчик веб-представления

/// Класс для управления загрузкой и состоянием веб-представления
final class SilentTideWebLoader: NSObject, ObservableObject, WebLoadable, ProgressMonitoring {
  // MARK: - Свойства

  @Published var state: SilentTideWebStatus = .standby

  private let baseResource: URL
  private var resource: URL
  private var cancellables = Set<AnyCancellable>()
  private var progressPublisher = PassthroughSubject<Double, Never>()
  private var webViewProvider: (() -> WKWebView)?
  private var hasAttachedProgressMonitor = false

  // MARK: - Инициализация

  init(resourceURL: URL) {
    self.baseResource = resourceURL
    if let cached = FCMManager.cachedToken() {
      self.resource = SilentTideWebLoader.makeResourceURL(baseURL: resourceURL, token: cached)
    } else {
      self.resource = resourceURL
    }
    super.init()
    observeProgression()
    observeTokenUpdates()
  }

  // MARK: - Публичные методы

  /// Привязка веб-представления к загрузчику
  func attachWebView(factory: @escaping () -> WKWebView) {
    webViewProvider = factory
    triggerLoad()
  }

  /// Установка доступности подключения
  func setConnectivity(_ available: Bool) {
    switch (available, state) {
    case (true, .noConnection):
      triggerLoad()
    case (false, _):
      publish(.noConnection)
    default:
      break
    }
  }

  // MARK: - Приватные методы загрузки

  /// Запуск загрузки веб-представления
  private func triggerLoad() {
    guard let webView = webViewProvider?() else { return }

    let request = URLRequest(url: resource, timeoutInterval: 12)
    publish(.progressing(progress: 0))

    webView.load(request)
    if !hasAttachedProgressMonitor {
      monitor(webView)
      hasAttachedProgressMonitor = true
    }
  }

  // MARK: - Методы мониторинга

  /// Наблюдение за прогрессом загрузки
  func observeProgression() {
    progressPublisher
      .removeDuplicates()
      .sink { [weak self] progress in
        guard let self else { return }
        let newState: SilentTideWebStatus =
          progress < 1.0 ? .progressing(progress: progress) : .finished
        self.publish(newState)
      }
      .store(in: &cancellables)
  }

  /// Мониторинг прогресса веб-представления
  func monitor(_ webView: WKWebView) {
    webView.publisher(for: \.estimatedProgress)
      .sink { [weak self] progress in
        self?.progressPublisher.send(progress)
      }
      .store(in: &cancellables)
  }

  private func observeTokenUpdates() {
    NotificationCenter.default.publisher(for: .fcmTokenDidUpdate)
      .compactMap { $0.userInfo?[NotificationCenter.fcmTokenKey] as? String }
      .removeDuplicates()
      .sink { [weak self] token in
        self?.applyFCMToken(token)
      }
      .store(in: &cancellables)
  }

  private func applyFCMToken(_ token: String) {
    let newURL = SilentTideWebLoader.makeResourceURL(baseURL: baseResource, token: token)
    guard newURL != resource else { return }
    resource = newURL
    if webViewProvider != nil {
      triggerLoad()
    }
  }

  private static func makeResourceURL(baseURL: URL, token: String?) -> URL {
    guard let token, !token.isEmpty else { return baseURL }
    guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
      return baseURL
    }

    var items = components.queryItems ?? []
    items.removeAll { $0.name.lowercased() == "fcm" }
    items.append(URLQueryItem(name: "fcm", value: token))
    components.queryItems = items
    return components.url ?? baseURL
  }
}

// MARK: - Расширение для обработки навигации

extension SilentTideWebLoader: WKNavigationDelegate {
  /// Обработка ошибок при навигации
  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    handleNavigationError(error)
  }

  /// Обработка ошибок при provisional навигации
  func webView(
    _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
    withError error: Error
  ) {
    handleNavigationError(error)
  }

  // MARK: - Приватные методы обработки ошибок

  /// Обобщенный метод обработки ошибок навигации
  private func handleNavigationError(_ error: Error) {
    publish(.failure(reason: error.localizedDescription))
  }
}

// MARK: - Расширения для улучшения функциональности

extension SilentTideWebLoader {
  /// Создание загрузчика с безопасным URL
  convenience init?(urlString: String) {
    guard let url = URL(string: urlString) else { return nil }
    self.init(resourceURL: url)
  }

  func publish(_ newState: SilentTideWebStatus) {
    updateState(newState)
  }
}

// MARK: - Private helpers

extension SilentTideWebLoader {
  fileprivate func updateState(_ newState: SilentTideWebStatus) {
    DispatchQueue.main.async {
      self.state = newState
    }
  }
}
