#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter create --platforms=android,windows --project-name veldigo --org com.brendigo .
python3 tools/configure_android.py
flutter pub get
echo "Veldigo platform scaffolds created. Check android/app/build.gradle.kts: minSdk >= 24."
