# Передача работы следующему AI-агенту

Обновлено: 15 июля 2026 года.

Ниже находится готовый промт. Его можно целиком передать другому агенту.

---

Ты продолжаешь работу над Flutter-проектом Exam Trainer:

`/home/igor/project/exam_trainer`

Связанный backend и каноническое описание продукта:

`/home/igor/project/exam-trainer-api`

## Обязательный контекст

Перед любыми изменениями полностью прочитай:

1. инструкции `AGENTS.md`, доступные в рабочем окружении;
2. `/home/igor/project/exam_trainer/CODE_REVIEW_2026-07-15.md`;
3. `/home/igor/project/exam-trainer-api/PRODUCT_PLAN.md`;
4. этот файл `/home/igor/project/exam_trainer/NEXT_AGENT_PROMPT.md`.

До записи кода найди релевантный контекст в Hermes Memory по ключевым словам
`Exam Trainer P0 P1 CR-07 cloud sync outbox device gate API errors Android
privacy`. Для структурного анализа определений, callers, callees, зависимостей
и impact используй CodeGraph; для literal search используй `rg`. Если индекс
CodeGraph недоступен или неактуален, не запускай его инициализацию без
разрешения пользователя.

## Текущее подтверждённое состояние

P0 CR-01—CR-06 уже исправлены. Не переделывай их без новой подтверждённой
регрессии:

- CR-01: атомарная локальная запись курсов, покурсовая обработка повреждений,
  quarantine `.corrupt`, UID-изоляция;
- CR-02: path-based PDF picker, лимит 25 MiB, проверка `%PDF-`, streamed upload
  без нескольких полных копий файла на клиенте;
- CR-03: lifecycle-safe `PdfImportController`, operation generation,
  invalidation при dispose/повторном запуске, отсутствие поздних save/navigation;
- CR-04: конечные loading/content/not-found/error состояния курса, секций и
  упражнений вместо бесконечных spinner;
- CR-05: release signing fail-closed, автоматического debug signing нет;
- CR-06: стабильный fake PDF → курс → Home → упражнение → результат → reload
  smoke flow без production backend.

Последний проверенный baseline:

- `dart format --output=none --set-exit-if-changed .` — проходит;
- `flutter analyze` — без замечаний;
- `flutter test` — 132/132;
- `flutter test --coverage` — 1555/4115 строк, 37,79%;
- device integration smoke — 1/1 на физическом Samsung;
- production release APK собирается в
  `build/app/outputs/flutter-apk/app-production-release.apk`;
- APK имеет applicationId `com.linguaproapps.exam_trainer`, versionCode 10,
  versionName 1.0.0 и ожидаемый upload-сертификат;
- изолированная release-сборка без `android/key.properties` прекращается с
  понятной ошибкой и не использует debug key;
- `git diff --check` проходит.

Android flavors:

- `production` — flavor по умолчанию, прежний production applicationId;
- `integration` — `com.linguaproapps.exam_trainer.integration`, только local
  fakes, без отдельного Firebase-конфига.

Критически важно: на физическом телефоне с production-приложением нельзя
запускать прямой `flutter test -d <device> integration_test/...`. Flutter
teardown уже удалял base production package вместе с локальными данными.
Единственный поддерживаемый запуск:

```bash
tool/run_android_integration.sh <device-id>
```

Скрипт использует `--flavor integration --no-uninstall`, удаляет только точный
integration package и проверяет сохранность production package даже при падении
теста. Не устанавливай поверх production debug APK и не создавай временный
keystore.

## Состояние Git и сохранность пользовательской работы

Проверенный P0 implementation и тесты сохранены локальным Flutter-коммитом
`276afdb` (`fix: harden PDF course flow and release safety`). Документация
handoff сохранена следующим отдельным docs-коммитом. Эти commits не отправлены
во внешний remote.

Перед началом обязательно выполни `git status --short` и изучи изменения после
этого baseline. Любой новый tracked/untracked diff считай пользовательской
работой. Не применяй `git reset`, `git checkout --`, массовый revert или очистку
untracked-файлов. Не создавай новые commits и не отправляй изменения наружу без
актуального разрешения пользователя.

В implementation-коммите присутствует большой formatter-only diff
существующих Dart-файлов после обязательного `dart format .`; он уже является
частью baseline и не требует отделения. В backend-репозитории канонический
`PRODUCT_PLAN.md` обновлён отдельным docs-коммитом; существующий untracked
`.idea/` не трогать.

Ключевые новые/изменённые точки:

- `lib/services/course_storage.dart`;
- `lib/services/parse_service.dart`;
- `lib/screens/import_screen.dart`;
- `lib/ui/features/import/`;
- `lib/widgets/course_load_state.dart` и связанные course/exercise screens;
- `android/app/build.gradle.kts`, `pubspec.yaml`;
- `integration_test/`, `test/integration/`, P0 regression tests;
- `tool/run_android_integration.sh`;
- `CODE_REVIEW_2026-07-15.md` и
  `/home/igor/project/exam-trainer-api/PRODUCT_PLAN.md`.

## Следующая задача: P1

Проверь по текущему коду и последовательно исправляй подтверждённые CR-07—CR-12.
Не исправляй предположение из отчёта, если текущий код его не подтверждает.
Начни с CR-07 и после каждого CR добавляй или обновляй тесты. Избегай полной
архитектурной переписи; новые компоненты направляй как
UI → Controller/ViewModel → Repository/Service. Не добавляй state-management
framework.

Порядок и ожидаемый результат:

1. **CR-07 — cloud sync delivery.** Точно проследи текущие upload/delete paths,
   callers и failure handling. Для подтверждённого best-effort поведения добавь
   минимальную persistent outbox/tombstones модель, идемпотентное повторение и
   видимый sync state, сохранив UID-изоляцию и локальную доступность. Не меняй
   backend API без доказанной необходимости. Если для revisions/idempotency
   нужен контракт backend, сначала документируй причину и минимальный обратно
   совместимый вариант, затем запроси решение пользователя перед изменением
   внешнего контракта.
2. **CR-08 — dynamic schema.** Не переписывай все упражнения сразу. Закрой
   наиболее опасные входные границы defensive parsing/typed DTO, добавь
   `schemaVersion`/contract fixtures там, где это совместимо, и обеспечь
   безопасный `int.tryParse`/not-found для маршрутов.
3. **CR-09 и CR-10 — startup/device gate.** Сначала измерь и проследи холодный
   путь и typed outcomes. Не ломай существующий startup overlay. Раздели
   confirmed limit, auth failures, server failures и offline; используй только
   явно обоснованный cached allow/grace policy. Если продуктовая политика
   неоднозначна и влияет на платный доступ, остановись и запроси решение, не
   выбирай fail-open/fail-closed молча.
4. **CR-11 — API errors.** Введи безопасные typed errors на границе сервиса.
   Пользователь должен видеть локализованные сообщения и действия для
   401/403/413/timeout/5xx, но не raw exception, response body, токены или
   персональные данные.
5. **CR-12 — Android privacy.** Сверь manifest permissions и backup policy с
   реально используемыми возможностями и актуальными Android требованиями.
   Удали только доказанно лишние разрешения, добавь manifest/config tests и не
   ослабляй Firebase/UID-защиту.

Для каждого CR зафиксируй: подтверждение по коду, impact, минимальное решение,
изменённые файлы, тесты, результат проверки и остаточный риск. Сохраняй
Free/Premium, production API, Firebase Auth, caching и текущие course formats.
Не показывай пользователю необработанные backend errors. Не добавляй секреты,
keystore, токены или персональные данные.

## Проверка и документация

После каждого CR запускай точечные тесты. В конце выполни:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter test --coverage
tool/run_android_integration.sh <device-id>
flutter build apk --release
git diff --check
```

Для release дополнительно проверь applicationId/version и сертификат через
Android build tools. В отдельной копии без signing-файлов подтверди fail-closed;
не копируй и не печатай содержимое `key.properties`. Перед device smoke сначала
убедись, что устройство подключено, и используй только защитный скрипт.

Просмотри полный diff обоих репозиториев на случай посторонних изменений.
Обновляй, не удаляя историю:

- раздел `Статус реализации` в `CODE_REVIEW_2026-07-15.md`;
- `/home/igor/project/exam-trainer-api/PRODUCT_PLAN.md`;
- этот handoff, если baseline или безопасные команды изменились.

После успешной полной проверки сохрани 2–3 предложения в Hermes Memory с
префиксом `[project:/home/igor/project/exam_trainer]`. В финальном отчёте укажи
подтверждённые/неподтверждённые CR, файлы, тесты, результаты всех gates,
оставшиеся риски и следующий безопасный шаг. Не создавай commit.

---

## Примечание для пользователя

Этот handoff фиксирует проверенный локальный baseline, а не опубликованный
Git-релиз или Play artifact. Архивный AAB versionCode 10 создан до P0 и не
должен загружаться; следующая публикация требует нового versionCode и полного
release gate. Любые изменения поверх указанных commits необходимо сохранять и
не считать временными без доказательств.
