# Play Console Submission — Exam Trainer

Prepared as the Play Console reference deliverable from the canonical
`/home/igor/project/exam-trainer-api/PRODUCT_PLAN.md`. This document is
**text preparation only** — nothing here has been submitted to Google Play.
You (the Play Console account owner) still need to paste/upload everything
below yourself.

Sources used: `docs/privacy.html` (authoritative, currently-live policy),
`docs/delete-account.html`, `lib/l10n/strings.dart`,
`/home/igor/project/exam-trainer-api/firestore_client.py` and
`firebase_auth.py` (what actually gets written to Firestore/Firebase Auth),
`main.py` (`/api/account` endpoint), `pubspec.yaml` (dependency check for
analytics/ads SDKs — none found).

---

## 0. Status tracker

| Item | Status | Notes |
|---|---|---|
| Account deletion — in-app | **Done, E2E verified 2026-07-15** | A production test on a physical Android device completed the full `DELETE /api/account` flow: Firestore data and the Firebase Auth account were deleted, the app returned to login, and local course/scoped-preference storage was empty. This also verifies the service account's IAM permission for Firebase Auth deletion. |
| Account deletion — web form | **Done, live** | `https://bodia2010.github.io/exam-trainer/delete-account.html` was published to GitHub Pages on 2026-07-15 and verified with HTTP 200, the expected title, and all 4 language sections. Enter this URL in Play Console's Account deletion field. |
| Privacy policy URL | **Done, live** | https://bodia2010.github.io/exam-trainer/privacy.html — just paste this URL into Play Console's "Privacy Policy" field. |
| Data safety form | **Drafted below** | Needs manual transcription into the Play Console UI (it's a multi-step wizard, not a paste-in field). See Section 2. |
| Screenshots | **Not started** | No screenshots exist yet. See Section 3 for the checklist — requires a human or emulator pass, which this agent did not do. |
| Release signing | **Done, verified 2026-07-15** | Signed `1.0.0+5` AAB: `/home/igor/Downloads/exam-trainer-v36-release.aab`; bundletool validation passed, package is `com.linguaproapps.exam_trainer`, targetSdk 36, and the upload-certificate fingerprint matches the verified APK. SHA-256: `8e008ac787be7860a5c8bedbd8e8e211a44d0410e528fff3c063f77d933424b2`. |
| App description (4 languages) | **Drafted below** | See Section 4. Languages confirmed from `lib/l10n/` and `docs/privacy.html`: German, English, Russian, Ukrainian. |

---

## 1. Privacy policy URL

```
https://bodia2010.github.io/exam-trainer/privacy.html
```

Already live on GitHub Pages, covers all 4 app languages via an in-page
language switcher. Paste this exact URL into Play Console → **App content →
Privacy policy**. Nothing further needed here.

---

## 2. Data safety form

This maps what the backend (`exam-trainer-api`) actually reads/writes to
Firestore and Firebase Auth, cross-checked against `privacy.html`, to Play
Console's Data Safety taxonomy. No analytics, ads, or crash-reporting SDK is
present in `pubspec.yaml` (checked: only `firebase_core`, `firebase_auth`,
`google_sign_in` — no `firebase_analytics`, no `firebase_crashlytics`, no ad
SDK), so do **not** declare Advertising ID, Analytics, or Crash logs.

### Does the app collect or share user data? → **Yes, collects (no third-party sharing)**

All service providers listed below (Firebase, Google Sign-In, Gemini,
Vercel, Upstash) are infrastructure/processing sub-processors under the
developer's own backend — the app has no ad network, no analytics SDK, and
sends data to no third party for that party's own purposes. In Play
Console's terms this is **"No data shared with third parties."**

### Data types collected

| Play Console category | Specific data | Where it comes from in code | Purpose | Shared with 3rd parties? | Optional? | Deletable? |
|---|---|---|---|---|---|---|
| **Personal info → Email address** | User's email | Firebase Auth (client-side sign-in: email/password or Google Sign-In). Backend never stores it separately — only reads the verified UID from the ID token (`firebase_auth.py::verify_id_token`). | Account identity/authentication | No | No (required to use the app) | Yes — full account deletion |
| **Personal info → Name** | Display name | Firebase Auth (Google Sign-In profile) | Account identity | No | No, if signing in via Google; N/A for email/password | Yes |
| **Personal info → User IDs** | Firebase UID | Firebase Auth; used as the Firestore document key for every collection (`users/{uid}`, `users/{uid}/devices`, `users/{uid}/courses`) | Associate app data with the account | No | No | Yes |
| **Personal info → Other info** | Profile photo (URL) | Firebase Auth (Google Sign-In), not separately stored by the backend | Display in account UI | No | Yes (only if signing in via Google) | Yes (tied to account deletion) |
| **Files and docs** | Content of imported PDF exam materials, and the AI-generated exercises parsed from them | `firestore_client.py::save_course` writes the parsed course JSON to `users/{uid}/courses/{course_id}`; the raw PDF itself is only held in memory during conversion (`main.py::convert`), never persisted | Core app function — generate practice exercises from the user's own exam material | No (Gemini AI processes the text to generate exercises but does not retain it — per `privacy.html` §4) | Yes — the app is usable without importing (built-in `telc B2` practice sections) | Yes — deleting a course, or deleting the account, removes it |
| **App activity → App interactions / other user-generated content** | Exercise progress (subcollection reserved, not yet actively written per code comment) | `users/{uid}/progress` — declared in `_ACCOUNT_SUBCOLLECTIONS` but no write path exists yet in the current code | Track completed exercises (planned) | No | Yes | Yes |
| **App activity → Other actions** | Account status flag (free / premium) | `users/{uid}.isPremium` boolean, read by `firebase_auth.py::is_premium` | Gate premium features | No | N/A (system-set) | Yes |
| **Device or other IDs** | App-generated device ID + device name | `users/{uid}/devices/{deviceId}` (`deviceId`, `name`, `registeredAt`, `lastSeen`) written by `check_and_register_device`/`force_register_device` | Enforce a 2-device limit per account (anti-account-sharing) | No | No, if logged in (enforced automatically) | Yes |
| **Financial info** | None collected by this app's own backend | No Play Billing / payment code found in the reviewed backend files; if premium is granted via Play Billing purchase flow elsewhere, re-check before submitting | — | — | — | — |

### Security practices to declare

- Data is encrypted in transit (HTTPS to Firebase, Firestore REST API, and
  the Vercel backend — confirm this is literally true for your setup, it
  should be by default).
- Users can request data deletion: **Yes** — both in-app (`DELETE
  /api/account`) and via the web form (`docs/delete-account.html`), 30-day
  SLA on the manual path per the privacy policy.
- Data collection is not optional in the sense that an account is required
  for cloud sync/device-limit features, but note that the app's built-in
  `telc B2` content works without ever importing a PDF.

**Caveat to flag to yourself before submitting:** the "shared with third
parties" answer above assumes Play Console doesn't require you to disclose
Google (Firebase/Gemini/Sign-In) as a "third party" just because it's a
different Google product surface than the Play Store itself — this is the
standard interpretation (processor, not third party) but double-check
against Play's current data-safety help docs before finalizing, since
Google's own guidance on this specific point has shifted before.

---

## 3. Screenshots — NOT generated by this agent

No screenshots exist yet. This agent did not launch an emulator or capture
any images — this section is a checklist for a human (or a `run`-skill
emulator pass) to execute before submission. Play Store requires a minimum
of 2 screenshots per supported form factor (phone at minimum).

Suggested screens to capture, in a sensible funnel order:

- [ ] **Home screen** (`home_screen.dart`) — shows the "Practice sections" /
      "Own PDF" entry points, sets first impression
- [ ] **Import flow** (`import_screen.dart`) — PDF picker screen with the
      "telc B2 Beruf — Lesen, Hören, Sprachbausteine..." hint text visible
- [ ] **Section list after import** (`section_list_screen.dart` or
      `course_screen.dart`) — shows the AI-detected exam sections
- [ ] **An exercise screen** — pick one of the concrete exercise types, e.g.
      `sprachbausteine_exercise_screen.dart` (fill-in-the-blank) or
      `hoeren_teil1_exercise_screen.dart` (listening) — whichever looks most
      polished/representative
- [ ] **Speaking/oral exam screen** (`sprechen_exercise_screen.dart` or
      `smalltalk_exercise_screen.dart`) — the "Mündliche Prüfung" module is a
      distinct value prop worth showing separately
- [ ] **A results/feedback moment** — whatever in-exercise state shows
      correctness/score (check `universal_exercise_screen.dart` and the
      individual exercise screens for a results view — none of the file
      names suggest a dedicated "results" screen, so this may be a state
      within an exercise screen rather than a separate screen; verify when
      capturing)

Also needed (not code-derivable, purely asset work): a feature graphic
(1024×500), and an app icon at the required resolutions if not already
finalized.

---

## 4. App description — 4 languages

Confirmed supported languages from `lib/l10n/strings.dart`'s `_t(de, ru, uk,
en)` pattern and `docs/privacy.html`'s language switcher (`de`, `en`, `ru`,
`uk`): **German, English, Russian, Ukrainian.** No other languages are
implemented in the app UI, so no other Play Store listing languages should
be filled in as if the app supported them.

App identity used as the basis: name **"Exam Trainer"** (from
`AndroidManifest.xml` `android:label` and iOS `CFBundleDisplayName`), value
proposition drawn from `strings.dart`: import your own PDF exam material,
AI auto-detects the telc B2 Beruf sections (Lesen, Hören, Sprachbausteine,
Beschwerde, Telefonnotiz) and generates practice exercises from it, plus a
dedicated oral-exam ("Mündliche Prüfung" / Sprechen) practice module with
speaking topics. Trademark note: the app explicitly disclaims telc GmbH
affiliation (see `impressumTelcBody` in `strings.dart`) — that disclaimer
should also appear in the Play Store listing or at minimum in the app's
in-app legal page (already present), since using "telc" prominently in
marketing copy without the disclaimer nearby is a mild trademark-risk
smell worth being deliberate about. The short/long descriptions below keep
"telc B2 Beruf" as a descriptive/format reference rather than a brand claim.

### German (de)

**Short description** (~80 chars):
```
Übe für die telc B2 Beruf Prüfung mit KI-Übungen aus deinem eigenen PDF.
```
(74 characters)

**Long description:**
```
Exam Trainer hilft dir, dich gezielt auf die mündliche und schriftliche
telc B2 Beruf-Prüfung vorzubereiten — mit Übungen, die zu deinem eigenen
Lernmaterial passen.

Lade ein PDF mit Prüfungsaufgaben hoch — egal wie es aufgebaut ist — und
die App erkennt automatisch die enthaltenen Abschnitte: Lesen, Hören,
Sprachbausteine, Beschwerde, Telefonnotiz und mehr. Aus jedem Abschnitt
werden interaktive Übungen erzeugt, die du direkt in der App durchgehen
kannst.

Zusätzlich bietet Exam Trainer ein eigenes Modul für die mündliche
Prüfung (Sprechen) mit vorbereiteten Themen zum Üben von Small Talk und
Präsentation.

Funktionen:
• Eigene PDFs importieren — die KI findet die Prüfungsteile selbst
• Alle klassischen telc B2 Beruf-Abschnitte abgedeckt
• Separates Modul für die mündliche Prüfung
• Fortschritt und importierte Kurse geräteübergreifend synchronisiert
• Kostenlose Nutzung mit einer Variante pro Bereich; Premium schaltet
  mehr Varianten frei

Exam Trainer ist ein unabhängiges Lernwerkzeug und steht in keiner
Verbindung zur telc GmbH; "telc" wird ausschließlich als Bezeichnung des
Prüfungsformats verwendet, auf das sich die Übungen beziehen.
```

### English (en)

**Short description** (~80 chars):
```
Practice for the telc B2 Beruf exam with AI exercises from your own PDF.
```
(74 characters)

**Long description:**
```
Exam Trainer helps you prepare for the telc B2 Beruf exam — both written
and oral parts — with exercises generated from your own study material.

Upload a PDF with exam-style tasks, however it's formatted, and the app
automatically detects the sections inside it: reading comprehension,
listening, language modules (Sprachbausteine), formal complaint letters
(Beschwerde), phone message notes (Telefonnotiz), and more. Each section
becomes an interactive exercise you can work through right in the app.

Exam Trainer also includes a dedicated module for the oral exam
(Sprechen), with ready-made topics for practicing small talk and short
presentations.

Features:
• Import your own PDFs — the AI finds the exam sections on its own
• Covers all the classic telc B2 Beruf section types
• Separate module for oral exam practice
• Progress and imported courses sync across your devices
• Free to use with one variant per section; Premium unlocks more variants

Exam Trainer is an independent study tool and is not affiliated with telc
GmbH; "telc" is used only to describe the exam format the exercises are
based on.
```

### Russian (ru)

**Short description** (~80 chars, counted in characters not bytes):
```
Готовьтесь к экзамену telc B2 Beruf с ИИ-упражнениями по вашему PDF.
```
(69 characters)

**Long description:**
```
Exam Trainer помогает целенаправленно готовиться к устному и письменному
экзамену telc B2 Beruf — с упражнениями, созданными по вашим собственным
учебным материалам.

Загрузите PDF с экзаменационными заданиями — в любом оформлении — и
приложение автоматически определит разделы: Lesen (чтение), Hören
(аудирование), Sprachbausteine (языковые модули), Beschwerde (жалоба),
Telefonnotiz (телефонное сообщение) и другие. Из каждого раздела
создаются интерактивные упражнения, которые можно выполнять прямо в
приложении.

Кроме того, Exam Trainer включает отдельный модуль для подготовки к
устному экзамену (Sprechen) с готовыми темами для отработки small talk и
презентации.

Возможности:
• Импорт собственных PDF — ИИ сам находит разделы экзамена
• Все классические разделы telc B2 Beruf
• Отдельный модуль для устной части экзамена
• Прогресс и импортированные курсы синхронизируются между устройствами
• Бесплатное использование с одним вариантом на раздел; Премиум
  открывает больше вариантов

Exam Trainer — независимый учебный инструмент, не связанный с telc GmbH;
слово «telc» используется исключительно для обозначения формата
экзамена, на который ориентированы упражнения.
```

### Ukrainian (uk)

**Short description** (~80 chars):
```
Готуйтеся до іспиту telc B2 Beruf з ШІ-вправами за вашим власним PDF.
```
(70 characters)

**Long description:**
```
Exam Trainer допомагає цілеспрямовано готуватися до усного та письмового
іспиту telc B2 Beruf — за допомогою вправ, створених на основі ваших
власних навчальних матеріалів.

Завантажте PDF з екзаменаційними завданнями — незалежно від оформлення —
і застосунок автоматично визначить розділи: Lesen (читання), Hören
(аудіювання), Sprachbausteine (мовні модулі), Beschwerde (скарга),
Telefonnotiz (телефонне повідомлення) та інші. З кожного розділу
створюються інтерактивні вправи, які можна виконувати прямо в
застосунку.

Крім того, Exam Trainer має окремий модуль для підготовки до усного
іспиту (Sprechen) із готовими темами для відпрацювання small talk і
презентації.

Можливості:
• Імпорт власних PDF — ШІ сам знаходить розділи іспиту
• Усі класичні розділи telc B2 Beruf
• Окремий модуль для усної частини іспиту
• Прогрес та імпортовані курси синхронізуються між пристроями
• Безкоштовне використання з одним варіантом на розділ; Преміум відкриває
  більше варіантів

Exam Trainer — незалежний навчальний інструмент, не пов'язаний з telc
GmbH; слово «telc» використовується виключно для позначення формату
іспиту, на який орієнтовані вправи.
```

---

## What's left for you to do

1. Paste the privacy policy URL (Section 1) into Play Console.
2. Work through the Data Safety wizard in Play Console using Section 2 as
   your answer key — it's a click-through form, not a paste target.
3. Capture the screenshots in Section 3 (emulator or device).
4. Paste the descriptions from Section 4 into the Store Listing for each
   of the 4 languages Play Console offers as a locale.
5. Enter the live account-deletion URL from Section 0 in Play Console's
   Account deletion field.
6. Upload the verified signed AAB from
   `/home/igor/Downloads/exam-trainer-v36-release.aab` (versionCode 5).
