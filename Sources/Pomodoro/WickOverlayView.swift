import SwiftUI

/// Geometry for a rectangular wick framing the screen, parameterised 0→1
/// clockwise starting from the top-left corner.
private struct Perimeter {
  let rect: CGRect

  // Clockwise edge lengths from top-left: top, right, bottom, left.
  var top: CGFloat { rect.width }
  var right: CGFloat { rect.height }
  var bottom: CGFloat { rect.width }
  var left: CGFloat { rect.height }
  var length: CGFloat { top + right + bottom + left }

  /// The full wick path, drawn clockwise from the top-left so that
  /// `trimmedPath(from: 0, to: t)` matches `point(at: t)`.
  var path: Path {
    Path { p in
      p.move(to: CGPoint(x: rect.minX, y: rect.minY))
      p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
      p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
      p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
      p.closeSubpath()
    }
  }

  /// Point at fraction `t` (0→1) along the perimeter, clockwise from top-left.
  func point(at t: CGFloat) -> CGPoint {
    var d = max(0, min(t, 1)) * length
    if d <= top {
      return CGPoint(x: rect.minX + d, y: rect.minY)
    }
    d -= top
    if d <= right {
      return CGPoint(x: rect.maxX, y: rect.minY + d)
    }
    d -= right
    if d <= bottom {
      return CGPoint(x: rect.maxX - d, y: rect.maxY)
    }
    d -= bottom
    return CGPoint(x: rect.minX, y: rect.maxY - d)
  }
}

struct WickOverlayView: View {
  var progress: Double
  var isAlmostUp: Bool = false

  private let inset: CGFloat = 6
  private let lineWidth: CGFloat = 5

  private let freshColor = Color(red: 1.0, green: 0.72, blue: 0.28) // warm amber, glowing
  private let ashColor = Color(white: 0.45, opacity: 0.85)          // spent fuse, dim grey

  var body: some View {
    GeometryReader { geo in
      let perimeter = Perimeter(
        rect: CGRect(origin: .zero, size: geo.size).insetBy(dx: inset, dy: inset)
      )
      let flamePoint = perimeter.point(at: CGFloat(progress))

      ZStack {
        Canvas { context, _ in
          let path = perimeter.path
          let stroke = StrokeStyle(lineWidth: lineWidth, lineCap: .round)
          let burnt = path.trimmedPath(from: 0, to: progress)
          let remaining = path.trimmedPath(from: progress, to: 1)

          // Spent fuse behind the flame — distinct dim ash, visible on any backdrop.
          context.stroke(burnt, with: .color(ashColor), style: stroke)

          // Fresh fuse ahead of the flame — glow underlay then crisp amber on top.
          context.drawLayer { layer in
            layer.addFilter(.blur(radius: 6))
            layer.stroke(remaining, with: .color(freshColor.opacity(0.6)),
                         style: StrokeStyle(lineWidth: lineWidth + 6, lineCap: .round))
          }
          context.stroke(remaining, with: .color(freshColor), style: stroke)
        }

        if isAlmostUp {
          UrgencyCue(framePath: perimeter.path, flamePoint: flamePoint)
        }

        FlameView()
          .position(flamePoint)
          .animation(.linear(duration: 1), value: flamePoint)
      }
    }
    .ignoresSafeArea()
  }
}

/// Final-minute alarm: the whole frame pulses red-orange and embers rise off
/// the flame. Self-animating via `TimelineView`; only mounted when almost up.
private struct UrgencyCue: View {
  let framePath: Path
  let flamePoint: CGPoint

  private let sparkCount = 8
  private let ember = Color(red: 1.0, green: 0.35, blue: 0.1)
  private let spark = Color(red: 1.0, green: 0.8, blue: 0.35)

  var body: some View {
    TimelineView(.animation) { timeline in
      let t = timeline.date.timeIntervalSinceReferenceDate
      Canvas { context, _ in
        // Pulsing glow around the whole frame.
        let pulse = 0.3 + 0.45 * (0.5 + 0.5 * sin(t * 5))
        context.drawLayer { layer in
          layer.addFilter(.blur(radius: 10))
          layer.stroke(framePath, with: .color(ember.opacity(pulse)),
                       style: StrokeStyle(lineWidth: 10, lineCap: .round))
        }

        // Embers rising off the flame.
        for i in 0..<sparkCount {
          let phase = ((t * 1.6) + Double(i) / Double(sparkCount))
            .truncatingRemainder(dividingBy: 1)
          let rise = CGFloat(phase) * 28
          let drift = CGFloat(sin(Double(i) * 12.9898 + t * 2)) * 9
          let p = CGPoint(x: flamePoint.x + drift, y: flamePoint.y - rise)
          let radius = 2.4 * (1 - 0.5 * CGFloat(phase))
          let dot = Path(ellipseIn: CGRect(x: p.x - radius, y: p.y - radius,
                                           width: radius * 2, height: radius * 2))
          context.fill(dot, with: .color(spark.opacity(1 - phase)))
        }
      }
    }
  }
}

/// A glowing ember at the burning point, with a subtle idle flicker.
private struct FlameView: View {
  @State private var flicker = false

  var body: some View {
    ZStack {
      Circle()
        .fill(
          RadialGradient(
            colors: [Color.white, Color(red: 1.0, green: 0.85, blue: 0.4), Color(red: 1.0, green: 0.45, blue: 0.1).opacity(0)],
            center: .center, startRadius: 1, endRadius: 18
          )
        )
        .frame(width: 36, height: 36)
        .blur(radius: 2)

      Circle()
        .fill(Color.white)
        .frame(width: 7, height: 7)
        .blur(radius: 0.5)
    }
    .scaleEffect(flicker ? 1.12 : 0.92)
    .opacity(flicker ? 1.0 : 0.85)
    .shadow(color: Color(red: 1.0, green: 0.5, blue: 0.1).opacity(0.8), radius: 10)
    .onAppear {
      withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
        flicker = true
      }
    }
  }
}
