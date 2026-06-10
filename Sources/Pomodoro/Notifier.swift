import Foundation

/// Posts a macOS banner without bundling the app. `UNUserNotificationCenter`
/// needs a real `.app` bundle, which the bare-binary build doesn't provide, so
/// we shell out to `osascript`. No `sound name` is set, so the banner is silent.
enum Notifier {
  static func banner(_ message: String, title: String = "Pomodoro") {
    let script = "display notification \(quote(message)) with title \(quote(title))"
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    process.arguments = ["-e", script]
    try? process.run()
  }

  /// AppleScript string literal: wrap in quotes and escape backslashes/quotes.
  private static func quote(_ text: String) -> String {
    let escaped = text
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
    return "\"\(escaped)\""
  }
}
