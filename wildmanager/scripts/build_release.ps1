# Release build met buildnummer = datum (YYYYMMDD). Handig voor issues en deployed versie.
$buildNumber = Get-Date -Format "yyyyMMdd"
Write-Host "Building with build number: $buildNumber"
flutter build apk --build-number=$buildNumber
