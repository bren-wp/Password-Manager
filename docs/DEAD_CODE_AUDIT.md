# Veldigo — dead code and dependency audit

**Date:** 28 October 2026. **Scope:** tracked project tree, Flutter runtime code, Android/Windows native projects, GitHub Actions, documentation and assets.

## Removed from the active PR

| Asset/file | Reason |
|---|---|
| `assets/showcase/android.svg`, `assets/showcase/windows.svg` | Unused old illustrated mockups, superseded by 26 actual Flutter-rendered PNG screenshots embedded in README |
| `android/local.properties` | Generated, machine-specific SDK/Flutter paths; should never be tracked |
| `android/veldigo_android.iml` | IDE-generated module metadata |
| `windows/flutter/ephemeral/.plugin_symlinks/*` (5 tracked links) | Transient links into a specific toolchain; recreated by Flutter when dependencies resolve |
| `.github/workflows/scaffold.yml` | One-time platform generator bound to an already-merged obsolete branch |
| Inactive biometric/cloud settings and QR roadmap text | No working user action; avoid misleading or developer-style UI placeholders |
| Duplicated inline TOTP decoding/generation | Consolidated in `lib/core/totp.dart`, with strict seed tests |
| Obsolete file-picker v10 APIs | Migrated to v13 federated API; removed legacy picker results, eager data reads and duplicated path handling |
| Duplicated backup reads | Consolidated in one bounded file reader and used by both import flows |
| File-system import no longer referenced by backup UI | Removed to keep analyzer output clean |

## Retained deliberately (not dead)

- Android and Windows native generated registrants, CMake resources, icon files and manifests: required by native Flutter builds.
- `tools/configure_android.py` and `tools/generate_brand_icons.py`: referenced by CI and native bootstrap scripts.
- `scripts/bootstrap.sh` and `scripts/bootstrap.ps1`: manual cross-platform regeneration support, although no longer called by the retired one-time CI workflow.
- `tool/marketing_screenshots_test.dart`, `tools/publish_real_screenshots.py` and screenshot workflow: required to capture and check the README's 26 rendered screen images.
- `pubspec.lock`: intentional dependency-version reproducibility. Do not delete.
- Historical release notes/requests: historical traceability; old requests do not trigger the current release workflow.

## Static audit and remaining verification

- `flutter analyze` checks unresolved imports and unused local symbols. The project CI also runs `flutter test` and native builds.
- Check `pubspec.lock` transitive dependencies with a current vulnerability database before a production signoff. Static package-version checks are *not* the same as a CVE audit.
- Reachability was traced across `lib/main.dart`, screen/navigation components, vault persistence, native launchers and workflow entrypoints. No runtime feature was removed solely because its reference was not visible in the main navigation.
- Generated test screenshot fixtures are intentionally committed for README and are **not** secret vault data or unused image assets.
- As a follow-up, consider removing obsolete release-request trigger files once release provenance/history is archived; do not rewrite or delete published Git tags.

**Outcome:** identified orphaned generated files and visual mockups were removed; high-value shared logic was deduplicated; no claims of exhaustive binary-level dead-code elimination are made without linked native release analysis.
