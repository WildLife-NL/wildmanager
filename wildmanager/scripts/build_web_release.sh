#!/usr/bin/env bash
# Web release build: version = builddatum (vYYYYMMDD), daarna flutter build web --release.
set -e
SCRIPT_DIR="$(dirname "$0")"
"$SCRIPT_DIR/set_version_to_date.sh"
cd "$SCRIPT_DIR/.."
flutter build web --release
echo "Web release build done. Version is build date (see pubspec.yaml)."
