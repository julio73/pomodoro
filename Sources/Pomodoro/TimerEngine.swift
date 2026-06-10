import Foundation
import Observation

@MainActor
@Observable
final class TimerEngine {
  /// Total length of a focus session, in seconds.
  private(set) var totalDuration: TimeInterval

  private(set) var remaining: TimeInterval
  private(set) var isRunning = false

  /// Called when the session reaches 0. Set by the app to fire a notification.
  @ObservationIgnored var onComplete: (() -> Void)?

  @ObservationIgnored private var ticker: Timer?

  init(totalDuration: TimeInterval = 25 * 60) {
    self.totalDuration = totalDuration
    self.remaining = totalDuration
  }

  /// Fraction of the session consumed, 0 (fresh) → 1 (done).
  var progress: Double {
    guard totalDuration > 0 else { return 0 }
    return (totalDuration - remaining) / totalDuration
  }

  /// True in the final minute of a running session — drives the end-of-session cue.
  var isAlmostUp: Bool {
    isRunning && remaining > 0 && remaining <= 60
  }

  /// Change the session length and start fresh at the new duration.
  func setDuration(_ seconds: TimeInterval) {
    totalDuration = seconds
    reset()
  }

  var clockString: String {
    let total = Int(remaining.rounded(.up))
    return String(format: "%d:%02d", total / 60, total % 60)
  }

  func start() {
    guard !isRunning else { return }
    if remaining <= 0 { remaining = totalDuration }
    isRunning = true
    let ticker = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
      MainActor.assumeIsolated { self?.tick() }
    }
    RunLoop.main.add(ticker, forMode: .common)
    self.ticker = ticker
  }

  func pause() {
    isRunning = false
    ticker?.invalidate()
    ticker = nil
  }

  func reset() {
    pause()
    remaining = totalDuration
  }

  func toggle() {
    isRunning ? pause() : start()
  }

  private func tick() {
    remaining = max(0, remaining - 1)
    if remaining <= 0 {
      pause()
      onComplete?()
    }
  }
}
