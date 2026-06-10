#!/usr/bin/env bash
# Web release build: version = builddatum (vYYYYMMDD), daarna flutter build web --release.
set -e
SCRIPT_DIR="$(dirname "$0")"
"$SCRIPT_DIR/set_version_to_date.sh"
cd "$SCRIPT_DIR/.."

if [[ ! -f .env ]]; then
  echo "ERROR: .env ontbreekt (kopieer .env.example naar .env)" >&2
  exit 1
fi

DEV_BASE_URL="$(grep -E '^[[:space:]]*DEV_BASE_URL[[:space:]]*=' .env | head -n1 | cut -d= -f2- | tr -d '\r' | xargs)"
if [[ -z "$DEV_BASE_URL" ]]; then
  echo "ERROR: DEV_BASE_URL ontbreekt in .env" >&2
  exit 1
fi

flutter build web --release --dart-define=DEV_BASE_URL="$DEV_BASE_URL"
echo "Web release build done. API: $DEV_BASE_URL"
