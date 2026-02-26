# Chrome release run met buildnummer = datum (YYYYMMDD).
$buildNumber = Get-Date -Format "yyyyMMdd"
Write-Host "Running Chrome release with build number: $buildNumber"
flutter run -d chrome --release --build-number=$buildNumber
