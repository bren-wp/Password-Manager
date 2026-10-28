$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
flutter create --platforms=android,windows --project-name veldigo --org com.brendigo .
python tools/configure_android.py
flutter pub get
Write-Host 'Veldigo Android/Windows platform project generated.'
