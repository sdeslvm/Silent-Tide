import SwiftUI

@main
struct SilentTideApp: App {
  @UIApplicationDelegateAdaptor(SilentTideAppDelegate.self) private var appDelegate

  var body: some Scene {
    WindowGroup {
      SilentTideGameInitialView()
    }
  }
}
