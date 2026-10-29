#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get
flutter test test/local_crypto_smoke_test.dart --reporter expanded
