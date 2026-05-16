#!/bin/sh
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
export PATH="$PATH:$HOME/go/bin:/opt/homebrew/bin"

command -v gomobile >/dev/null || {
  echo "gomobile not found, run: go install golang.org/x/mobile/cmd/gomobile@latest"
  exit 1
}
command -v gobind >/dev/null || {
  echo "gobind not found, run: go install golang.org/x/mobile/cmd/gobind@latest"
  exit 1
}

cd "$ROOT"
gomobile bind -v -target=ios -o "$ROOT/Mobile.xcframework" ./mobile/ios
