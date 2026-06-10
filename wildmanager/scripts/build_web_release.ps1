# Web release build: version = builddatum (vYYYYMMDD), daarna flutter build web --release.
$ErrorActionPreference = "Stop"
& "$PSScriptRoot\set_version_to_date.ps1"
Set-Location $PSScriptRoot\..

$baseUrl = ''
if (Test-Path .env) {
  Get-Content .env | ForEach-Object {
    if ($_ -match '^\s*DEV_BASE_URL\s*=\s*(.+)$') {
      $baseUrl = $matches[1].Trim()
    }
  }
}
if ([string]::IsNullOrWhiteSpace($baseUrl)) {
  throw "DEV_BASE_URL ontbreekt in .env (kopieer .env.example naar .env)"
}

flutter build web --release --dart-define=DEV_BASE_URL=$baseUrl
Write-Host "Web release build done. API: $baseUrl"
