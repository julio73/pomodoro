import AppKit
import SwiftUI

/// Owns the small floating window with the clock and timer controls.
/// Minimizes to the Dock; closing it quits the app.
@MainActor
final class ControlPanelController: NSObject, NSWindowDelegate {
  private var window: NSWindow?
  private let engine: TimerEngine

  init(engine: TimerEngine) {
    self.engine = engine
    super.init()
  }

  func show() {
    guard window == nil else { return }

    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 220, height: 175),
      styleMask: [.titled, .closable, .miniaturizable],
      backing: .buffered,
      defer: false
    )
    window.title = "Pomodoro"
    window.level = .floating
    window.appearance = NSAppearance(named: .darkAqua)
    window.isMovableByWindowBackground = true
    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    window.delegate = self
    window.contentView = NSHostingView(rootView: ControlPanelView(engine: engine))

    if let screen = NSScreen.main {
      let frame = screen.visibleFrame
      window.setFrameOrigin(NSPoint(x: frame.maxX - 240, y: frame.maxY - 160))
    }

    window.makeKeyAndOrderFront(nil)
    self.window = window
  }

  /// Red close button quits the whole app rather than just hiding the window.
  func windowShouldClose(_ sender: NSWindow) -> Bool {
    NSApp.terminate(nil)
    return false
  }
}

private struct ControlPanelView: View {
  let engine: TimerEngine

  var body: some View {
    VStack(spacing: 12) {
      ClockLabel(engine: engine)
      DurationPicker(engine: engine)
      Controls(engine: engine)
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

/// Preset session lengths. Re-renders only when `totalDuration` changes.
private struct DurationPicker: View {
  let engine: TimerEngine

  private let presets: [Int] = [15, 25, 45]

  var body: some View {
    HStack(spacing: 6) {
      ForEach(presets, id: \.self) { minutes in
        let isSelected = Int(engine.totalDuration / 60) == minutes
        Button("\(minutes)m") {
          engine.setDuration(TimeInterval(minutes * 60))
        }
        .buttonStyle(.bordered)
        .tint(isSelected ? .orange : .gray)
      }
    }
    .controlSize(.small)
  }
}

/// Re-renders every tick (reads `clockString`); kept separate so the controls don't.
private struct ClockLabel: View {
  let engine: TimerEngine

  var body: some View {
    Text(engine.clockString)
      .font(.system(size: 38, weight: .semibold, design: .rounded))
      .monospacedDigit()
      .foregroundStyle(.white)
  }
}

/// Only re-renders when `isRunning` flips, so the buttons stay stable while time runs.
private struct Controls: View {
  let engine: TimerEngine

  var body: some View {
    HStack(spacing: 10) {
      Button(engine.isRunning ? "Pause" : "Start") {
        engine.toggle()
      }
      .keyboardShortcut(.space, modifiers: [])

      Button("Reset") {
        engine.reset()
      }
    }
    .controlSize(.large)
    .buttonStyle(.borderedProminent)
    .focusEffectDisabled()
  }
}
