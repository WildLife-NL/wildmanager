#!/bin/bash
set -e

FLUTTER_DIR="${FLUTTER_DIR:-$PWD/flutter}"
export PATH="$FLUTTER_DIR/bin:$PATH"

flutter build web --release
