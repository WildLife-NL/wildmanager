#!/usr/bin/env bash
# Chrome release run met buildnummer = datum (YYYYMMDD).
build_number=$(date +%Y%m%d)
echo "Running Chrome release with build number: $build_number"
flutter run -d chrome --release --build-number="$build_number"
