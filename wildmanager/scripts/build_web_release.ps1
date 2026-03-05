# Web release build: version = builddatum (vYYYYMMDD), daarna flutter build web --release.
$ErrorActionPreference = "Stop"
& "$PSScriptRoot\set_version_to_date.ps1"
Set-Location $PSScriptRoot\..
flutter build web --release
Write-Host "Web release build done. Version is build date (see pubspec.yaml)."
