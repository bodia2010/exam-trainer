# Exam Trainer — Flutter client

Android-first Flutter application that turns supported exam-preparation PDFs
into interactive exercises. The production backend is
`https://exam-trainer-api.vercel.app`.

The single current project plan and working instructions live in
`/home/igor/project/exam-trainer-api/PRODUCT_PLAN.md`. This README is only a
repository overview and does not duplicate operational rules.

Basic verification:

```bash
flutter test
flutter analyze
flutter build apk --release
```

The production APK is emitted as
`build/app/outputs/flutter-apk/app-production-release.apk`. A physical-device
integration test must be run only through:

```bash
tool/run_android_integration.sh <device-id>
```

The real Android system PDF picker has a separate opt-in, operator-assisted
smoke test. It uses an offline fake after file selection and never contacts the
production backend:

```bash
tool/run_android_saf_picker_smoke.sh <device-id>
```

Do not use a direct `flutter test -d ... integration_test/...` command on a
device containing the production app: Flutter teardown may remove its base
package and local data. Current implementation status and the next-agent
handoff are in `CODE_REVIEW_2026-07-15.md` and `NEXT_AGENT_PROMPT.md`.
