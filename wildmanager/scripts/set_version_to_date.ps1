# Zet pubspec.yaml version op builddatum (YYYYMMDD.0+YYYYMMDD) voor herkenning door onderzoekers.
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..
$date = Get-Date -Format "yyyyMMdd"
$version = "1.0.0+$date"
(Get-Content pubspec.yaml) -replace '^version: .*', "version: $version" | Set-Content pubspec.yaml
Write-Host "Version set to $version (v$date)"
