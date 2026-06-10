import AppKit
import SwiftUI

/// Owns the borderless, transparent, click-through window that paints the
/// burning wick around the main screen.
@MainActor
final class OverlayController {
  private var window: NSWindow?
  private let engine: TimerEngine

  init(engine: TimerEngine) {
    self.engine = engine
  }

  func show() {
    guard window == nil, let screen = NSScreen.main else { return }

    let window = NSWindow(
      contentRect: screen.frame,
      styleMask: .borderless,
      backing: .buffered,
      defer: false
    )
    window.isOpaque = false
    window.backgroundColor = .clear
    window.hasShadow = false
    window.ignoresMouseEvents = true
    window.level = .statusBar
    window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
    window.setFrame(screen.frame, display: true)

    let host = NSHostingView(rootView: OverlayRoot(engine: engine))
    host.layer?.isOpaque = false
    window.contentView = host

    window.orderFrontRegardless()
    self.window = window
  }
}

/// SwiftUI root that observes the engine and feeds progress to the wick.
private struct OverlayRoot: View {
  let engine: TimerEngine

  var body: some View {
    WickOverlayView(progress: engine.progress, isAlmostUp: engine.isAlmostUp)
  }
}
