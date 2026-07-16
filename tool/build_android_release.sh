#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

# Release artifacts must never depend on a stale incremental Flutter/Gradle
# snapshot. This is intentionally slower than a development build.
flutter clean
flutter pub get

# `flutter test`/integration_test can leave an ignored Android registrant that
# references the dev-only IntegrationTestPlugin. A subsequent clean release
# then compiles that stale Java file before Flutter replaces it. It is fully
# generated and ignored; removing it lets the release build regenerate the
# production-only plugin list.
registrant='android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java'
if [[ -f "$registrant" ]] && grep -q 'dev.flutter.plugins.integration_test' "$registrant"; then
  rm -- "$registrant"
fi

exec flutter build apk --release "$@"
