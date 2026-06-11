import AppKit
import SwiftUI

@MainActor
final class ControlPanelController: NSObject, NSWindowDelegate {
  private var window: NSWindow?
  private var clickMonitor: Any?
  private let engine: TimerEngine
  private let focus = FocusController()

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
    window.contentView = NSHostingView(rootView: ControlPanelView(engine: engine, focus: focus))

    if let screen = NSScreen.main {
      let frame = screen.visibleFrame
      window.setFrameOrigin(NSPoint(x: frame.maxX - 240, y: frame.maxY - 160))
    }

    window.makeKeyAndOrderFront(nil)
    window.initialFirstResponder = window.contentView
    self.window = window

    clickMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
      if event.window == self?.window {
        DispatchQueue.main.async { self?.focus.clear() }
      }
      return event
    }
  }

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    NSApp.terminate(nil)
    return false
  }
}

@MainActor
@Observable
private final class FocusController {
  var clearToken = 0
  func clear() { clearToken += 1 }
}

private enum FocusField: Hashable {
  case duration(Int)
  case start
  case reset
}

private struct ControlPanelView: View {
  let engine: TimerEngine
  let focus: FocusController
  @FocusState private var field: FocusField?

  var body: some View {
    VStack(spacing: 12) {
      ClockLabel(engine: engine)
      DurationPicker(engine: engine, field: $field)
      Controls(engine: engine, field: $field)
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onChange(of: focus.clearToken) { field = nil }
  }
}

private struct DurationPicker: View {
  let engine: TimerEngine
  @FocusState.Binding var field: FocusField?

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
        .focused($field, equals: .duration(minutes))
      }
    }
    .controlSize(.small)
  }
}

private struct ClockLabel: View {
  let engine: TimerEngine

  var body: some View {
    Text(engine.clockString)
      .font(.system(size: 38, weight: .semibold, design: .rounded))
      .monospacedDigit()
      .foregroundStyle(.white)
  }
}

private struct Controls: View {
  let engine: TimerEngine
  @FocusState.Binding var field: FocusField?

  var body: some View {
    HStack(spacing: 10) {
      Button(engine.isRunning ? "Pause" : "Start") {
        engine.toggle()
      }
      .focused($field, equals: .start)

      Button("Reset") {
        engine.reset()
      }
      .focused($field, equals: .reset)
    }
    .controlSize(.large)
    .buttonStyle(.borderedProminent)
  }
}
