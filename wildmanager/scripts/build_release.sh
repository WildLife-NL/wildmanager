#!/usr/bin/env bash
# Release build met buildnummer = datum (YYYYMMDD). Handig voor issues en deployed versie.
build_number=$(date +%Y%m%d)
echo "Building with build number: $build_number"
flutter build apk --build-number="$build_number"
