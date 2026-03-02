#!/bin/bash
set -e

FLUTTER_DIR="${FLUTTER_DIR:-$PWD/flutter}"

if [ -d "$FLUTTER_DIR" ]; then
  echo "Flutter directory exists, updating..."
  (cd "$FLUTTER_DIR" && git pull --rebase || true)
else
  echo "Cloning Flutter..."
  git clone https://github.com/flutter/flutter.git "$FLUTTER_DIR" --depth 1
fi

export PATH="$FLUTTER_DIR/bin:$PATH"
flutter config --enable-web --no-analytics
flutter doctor
flutter pub get
