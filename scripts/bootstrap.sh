#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter create --platforms=android,windows --project-name veldigo --org com.brendigo .
python3 tools/configure_android.py
python3 tools/generate_brand_icons.py
flutter pub get
echo "Veldigo Android and Windows projects generated with branded icons and security defaults."
