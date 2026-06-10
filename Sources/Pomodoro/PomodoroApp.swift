import AppKit
import SwiftUI

@main
struct PomodoroApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

  var body: some Scene {
    // No visible scene — the overlay and floating panel are AppKit windows
    // created by the delegate. Settings keeps SwiftUI's App lifecycle happy.
    Settings {
      EmptyView()
    }
  }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  let engine = TimerEngine()
  private var overlay: OverlayController?
  private var controlPanel: ControlPanelController?

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)

    engine.onComplete = {
      Notifier.banner("Time's up — session complete.")
    }

    let overlay = OverlayController(engine: engine)
    overlay.show()
    self.overlay = overlay

    let controlPanel = ControlPanelController(engine: engine)
    controlPanel.show()
    self.controlPanel = controlPanel
  }
}
