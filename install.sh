#!/usr/bin/env bash
# Build and install pomodoro. Works two ways:
#   - from a clone:   ./install.sh
#   - over the wire:  curl -fsSL https://raw.githubusercontent.com/julio73/pomodoro/main/install.sh | bash
set -euo pipefail

REPO="julio73/pomodoro"
BRANCH="main"
BIN_DIR="$HOME/.local/bin"

cleanup=""
trap '[ -n "$cleanup" ] && rm -rf "$cleanup"' EXIT

require() {
    command -v "$1" >/dev/null 2>&1 || { echo "error: '$1' is required but not found." >&2; exit 1; }
}
require swift
require curl

# Resolve the source directory: a local checkout if this script sits next to
# Package.swift, otherwise download the source (the curl | bash path).
src=""
script="${BASH_SOURCE[0]:-}"
if [ -n "$script" ] && [ -f "$script" ]; then
    here="$(cd "$(dirname "$script")" && pwd)"
    [ -f "$here/Package.swift" ] && src="$here"
fi
if [ -z "$src" ]; then
    echo "==> Downloading $REPO ($BRANCH)"
    cleanup="$(mktemp -d)"
    curl -fsSL "https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz" | tar -xz -C "$cleanup"
    src="$cleanup/pomodoro-$BRANCH"
fi

echo "==> Building (swift build -c release)"
( cd "$src" && swift build -c release )
binary="$(cd "$src" && swift build -c release --show-bin-path)/Pomodoro"

# Stop a running instance before replacing its binary.
pkill -x Pomodoro 2>/dev/null || true

echo "==> Installing to $BIN_DIR"
mkdir -p "$BIN_DIR"
install -m 0755 "$binary" "$BIN_DIR/pomodoro"

echo "==> Launching"
"$BIN_DIR/pomodoro" >/dev/null 2>&1 &
echo
case ":$PATH:" in
    *":$BIN_DIR:"*) echo "Installed. Run it any time with: pomodoro" ;;
    *) echo "note: $BIN_DIR is not on your PATH. Add it to use the short command name:"
       echo "      echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc"
       echo "      Until then, launch it by full path: $BIN_DIR/pomodoro" ;;
esac
