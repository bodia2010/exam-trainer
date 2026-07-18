#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <android-device-id>" >&2
  exit 64
fi

device_id="$1"
production_package="com.linguaproapps.exam_trainer"
integration_package="com.linguaproapps.exam_trainer.integration"
fixture_dir="/sdcard/Download/ExamTrainerSafFixture"
fixture_name="exam-trainer-saf-valid.pdf"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture_source="$repo_root/integration_test/fixtures/saf_valid_fixture.pdf"
production_was_installed=false
fixture_created=false

if adb -s "$device_id" shell pm path "$production_package" >/dev/null 2>&1; then
  production_was_installed=true
fi

cleanup() {
  test_status=$?
  trap - EXIT
  adb -s "$device_id" uninstall "$integration_package" >/dev/null 2>&1 || true
  if [[ "$fixture_created" == true ]]; then
    adb -s "$device_id" shell find "$fixture_dir" -depth -delete >/dev/null 2>&1 || true
  fi

  if [[ "$production_was_installed" == true ]] &&
    ! adb -s "$device_id" shell pm path "$production_package" >/dev/null 2>&1; then
    echo "ERROR: production package disappeared during SAF smoke" >&2
    exit 1
  fi
  exit "$test_status"
}

if adb -s "$device_id" shell test -e "$fixture_dir" >/dev/null 2>&1; then
  echo "ERROR: refusing to use existing device directory $fixture_dir" >&2
  echo "Move or remove it manually, then retry; the runner never deletes pre-existing data." >&2
  exit 73
fi

trap cleanup EXIT

adb -s "$device_id" shell mkdir -p "$fixture_dir"
fixture_created=true
adb -s "$device_id" push "$fixture_source" "$fixture_dir/$fixture_name" >/dev/null
adb -s "$device_id" shell am broadcast \
  -a android.intent.action.MEDIA_SCANNER_SCAN_FILE \
  -d "file://$fixture_dir/$fixture_name" >/dev/null

echo "Android SAF smoke requires one manual action."
echo "In the system picker open: Downloads > ExamTrainerSafFixture"
echo "Select: $fixture_name"
echo "No production backend or user course storage is used."

cd "$repo_root"
flutter test \
  --flavor integration \
  --no-uninstall \
  -d "$device_id" \
  integration_test/android_saf_picker_smoke_test.dart \
  -r expanded
