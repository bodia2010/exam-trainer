#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <android-device-id>" >&2
  exit 64
fi

device_id="$1"
production_package="com.linguaproapps.exam_trainer"
integration_package="com.linguaproapps.exam_trainer.integration"
production_was_installed=false

if adb -s "$device_id" shell pm path "$production_package" >/dev/null 2>&1; then
  production_was_installed=true
fi

cleanup() {
  test_status=$?
  trap - EXIT
  adb -s "$device_id" uninstall "$integration_package" >/dev/null 2>&1 || true

  if [[ "$production_was_installed" == true ]] &&
    ! adb -s "$device_id" shell pm path "$production_package" >/dev/null 2>&1; then
    echo "ERROR: production package disappeared during integration test" >&2
    exit 1
  fi

  exit "$test_status"
}
trap cleanup EXIT

# Flutter's default integration-test teardown may uninstall the unflavoured
# base package even when a flavored APK was used. Keep teardown disabled and
# remove only the exact integration package in the trap above.
flutter test \
  --flavor integration \
  --no-uninstall \
  -d "$device_id" \
  integration_test/pdf_course_smoke_test.dart \
  -r expanded

flutter test \
  --flavor integration \
  --no-uninstall \
  -d "$device_id" \
  integration_test/sprachbausteine_accessibility_smoke_test.dart \
  -r expanded
