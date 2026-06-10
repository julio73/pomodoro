# pomodoro

A Pomodoro timer for macOS that burns a glowing fuse around the edge of your
screen. A flame travels clockwise along the screen perimeter and leaves a charred
trail as your session counts down — when the loop closes, time's up. In the final
minute the whole frame pulses and embers rise off the flame so you get a clear
heads-up in peripheral vision.

A small floating control window (Start / Pause / Reset, duration presets) sits on
top of your work. There's no menu-bar item and no permanent Dock icon — minimize
the window to tuck it into the Dock, or close it to quit.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/julio73/pomodoro/main/install.sh | bash
```

…or from a clone:

```sh
git clone https://github.com/julio73/pomodoro.git
cd pomodoro
./install.sh
```

This builds a release binary, installs it to `~/.local/bin/pomodoro`, and launches
it. Run it any time afterwards with `pomodoro`.

## Run from source

```sh
swift run Pomodoro
```

## Controls

- **Start / Pause** — begin or hold the session (or press **Space**).
- **Reset** — back to a full session.
- **15m / 25m / 45m** — pick the session length.
- **Minimize** (yellow) — send the window to the Dock.
- **Close** (red) — quit the app.

When a session ends you get a silent macOS banner.

## Requirements

macOS 14+ and a Swift 6 toolchain (Xcode 16+).

## License

MIT — see [LICENSE](LICENSE).
