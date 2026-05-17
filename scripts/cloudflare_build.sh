#!/usr/bin/env bash
set -euo pipefail

FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"

if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 --branch "$FLUTTER_CHANNEL" "$FLUTTER_HOME"
else
  git -C "$FLUTTER_HOME" pull --ff-only
fi

export PATH="$FLUTTER_HOME/bin:$PATH"

flutter config --enable-web
flutter --version
flutter pub get
flutter build web --release
