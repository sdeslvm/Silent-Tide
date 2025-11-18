import Foundation
import SwiftUI

struct SilentTideEntryScreen: View {
  @StateObject private var loader: SilentTideWebLoader

  init(loader: SilentTideWebLoader) {
    _loader = StateObject(wrappedValue: loader)
  }

  var body: some View {
    ZStack {
      SilentTideWebViewBox(loader: loader)
        .opacity(loader.state == .finished ? 1 : 0.5)
      switch loader.state {
      case .progressing(let percent):
        SilentTideProgressIndicator(value: percent)
      case .failure(let err):
        SilentTideErrorIndicator(err: err)  // err теперь String
      case .noConnection:
        SilentTideOfflineIndicator()
      default:
        EmptyView()
      }
    }
  }
}

private struct SilentTideProgressIndicator: View {
  let value: Double
  var body: some View {
    GeometryReader { geo in
      SilentTideLoadingOverlay(progress: value)
        .frame(width: geo.size.width, height: geo.size.height)
        .background(Color.white)
    }
  }
}

private struct SilentTideErrorIndicator: View {
  let err: String  // было Error, стало String
  var body: some View {
    Text("Ошибка: \(err)").foregroundColor(.red)
  }
}

private struct SilentTideOfflineIndicator: View {
  var body: some View {
    Text("Нет соединения").foregroundColor(.gray)
  }
}
