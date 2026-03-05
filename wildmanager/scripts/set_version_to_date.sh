#!/usr/bin/env bash
# Zet pubspec.yaml version op builddatum (YYYYMMDD.0+YYYYMMDD) voor herkenning door onderzoekers.
set -e
cd "$(dirname "$0")/.."
DATE=$(date +%Y%m%d)
VERSION="${DATE}.0+${DATE}"
sed -i.bak "s/^version: .*/version: ${VERSION}/" pubspec.yaml && rm -f pubspec.yaml.bak
echo "Version set to ${VERSION} (v${DATE})"
