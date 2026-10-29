$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'Flutter dependency resolution failed' }
flutter test test/local_crypto_smoke_test.dart --reporter expanded
if ($LASTEXITCODE -ne 0) { throw 'Local cryptography regression tests failed' }
