import Foundation

// MARK: - Протоколы и расширения

/// Протокол для статусов с возможностью сравнения
protocol WebStatusComparable {
  func isEquivalent(to other: Self) -> Bool
}

// MARK: - Улучшенное перечисление статусов

/// Перечисление статусов веб-соединения с расширенной функциональностью
enum SilentTideWebStatus: Equatable, WebStatusComparable {
  case standby
  case progressing(progress: Double)
  case finished
  case failure(reason: String)
  case noConnection

  // MARK: - Пользовательские методы сравнения

  /// Проверка эквивалентности статусов с точным сравнением
  func isEquivalent(to other: SilentTideWebStatus) -> Bool {
    switch (self, other) {
    case (.standby, .standby),
      (.finished, .finished),
      (.noConnection, .noConnection):
      return true
    case (.progressing(let a), .progressing(let b)):
      return abs(a - b) < 0.0001
    case (.failure(let reasonA), .failure(let reasonB)):
      return reasonA == reasonB
    default:
      return false
    }
  }

  // MARK: - Вычисляемые свойства

  /// Текущий прогресс подключения
  var progress: Double? {
    guard case .progressing(let value) = self else { return nil }
    return value
  }

  /// Индикатор успешного завершения
  var isSuccessful: Bool {
    switch self {
    case .finished: return true
    default: return false
    }
  }

  /// Индикатор наличия ошибки
  var hasError: Bool {
    switch self {
    case .failure, .noConnection: return true
    default: return false
    }
  }
}

// MARK: - Расширения для улучшения функциональности

extension SilentTideWebStatus {
  /// Безопасное извлечение причины ошибки
  var errorReason: String? {
    guard case .failure(let reason) = self else { return nil }
    return reason
  }
}

// MARK: - Кастомная реализация Equatable

extension SilentTideWebStatus {
  static func == (lhs: SilentTideWebStatus, rhs: SilentTideWebStatus) -> Bool {
    lhs.isEquivalent(to: rhs)
  }
}
