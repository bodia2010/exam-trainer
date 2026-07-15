# Передача работы следующему AI-агенту

Обновлено 15 июля 2026 года после независимой перепроверки P1. Этот файл —
готовый prompt; его можно передать агенту целиком.

---

Ты продолжаешь работу над Exam Trainer:

- Flutter: `/home/igor/project/exam_trainer`
- backend: `/home/igor/project/exam-trainer-api`

Приложение импортирует пользовательский PDF, преобразует и индексирует его
через backend, сохраняет UID-изолированный курс и строит упражнения.

## Обязательный порядок

1. Полностью прочитай доступные `AGENTS.md`,
   `/home/igor/project/exam_trainer/CODE_REVIEW_2026-07-15.md`, этот файл и
   `/home/igor/project/exam-trainer-api/PRODUCT_PLAN.md`.
2. До записи кода найди Hermes Memory по ключам `Exam Trainer P1 independent
   review outbox UID device gate typed DTO P2 CR-13 CR-16`.
3. Проверь `git status --short`, последние commits и remote обеих веток.
   Не перезаписывай пользовательские изменения; `.idea/` backend не трогай.
4. Для definitions/callers/callees/impact используй CodeGraph, для literal
   search — `rg`. Если индекс отсутствует, не запускай init без разрешения.
5. Проверяй замечания по реальному коду. После каждого изменения добавляй
   тест; не делай полную архитектурную перепись.
6. Не деплой backend/Play artifact и не запускай платный Gemini/live PDF parse
   без отдельного разрешения.

## Проверенный baseline

P0 CR-01—CR-06 закрыты: атомарное и устойчивое local storage, безопасная
streamed PDF upload с лимитом 25 MiB и `%PDF-` magic, lifecycle-safe import,
конечные error/not-found состояния, fail-closed release signing и fake
PDF → курс → упражнение smoke flow.

P1 после независимой перепроверки:

- CR-07 закрыт. `CourseStorage` использует persistent per-UID outbox,
  сериализованные mutation, стабильные operation id, автоматический backoff и
  ручной retry с Home. Enqueue во время flush не теряется; запрос UID A не
  может уйти с токеном UID B. Повреждённый outbox quarantined. Account deletion
  приостанавливает sync и ждёт активный request.
- CR-08 частично закрыт. Невалидный route index и главные nested-list границы
  безопасны, есть `schemaVersion=1`, но полной typed DTO/migration модели нет.
  Не называй CR-08 полностью закрытым.
- CR-09/CR-10 закрыты в согласованной политике: startup не ждёт device check;
  блокирует только точный `200 {allowed:false}`. Malformed/auth/network/5xx
  fail-open. `DeviceGateController` отбрасывает stale result старого UID.
  Force action требует клиентское `{ok:true}`.
- CR-11 закрыт для import money-path: typed `ApiException`, локализованные
  безопасные ошибки; raw backend body отсутствует и в UI, и в debug details.
- CR-12 закрыт: лишних storage/media permissions нет, backup выключен,
  Android label — `Exam Trainer`.

Минимально совместимый backend contract был уточнён: `POST /api/device/force`
и `DELETE /api/courses/<id>` сохранили JSON `{ok: bool}`, но теперь возвращают
`200 {ok:true}` только после подтверждённого Firestore результата и
`503 {ok:false}` при storage failure. Production не развёртывался.

Последние фактические gates:

- `dart format --output=none --set-exit-if-changed .` — pass;
- `flutter analyze` — pass;
- `flutter test` — 191/191;
- `flutter test --coverage` — 1972/4503, 43,79%;
- backend — 72/72, `py_compile` pass;
- production APK — `com.linguaproapps.exam_trainer`, 1.0.0+10,
  `CN=Exam Trainer`, certificate SHA-256
  `84a3677cc24c58160c9fe3a9ce4befa09d204f7056d5efc4e795948850a92ea4`;
- build без `android/key.properties` — ожидаемый fail-closed exit 1;
- `git diff --check` — pass.

Проверенная реализация зафиксирована в Git:

- Flutter branch `phase5-account-deletion`, implementation commit `c61fa88`;
- backend branch `phase3-2-promptfoo-gate`, contract commit `5495185`;
- P0 baseline Flutter остаётся `276afdb`.

Документация зафиксирована отдельным commit после implementation. Сверь точный
HEAD через `git log -3 --oneline`; не полагайся на старое описание dirty tree.

В момент последней проверки телефон не был виден в `adb devices -l`, поэтому
device smoke не повторялся. Последний защищённый прогон был 1/1 на Samsung.
На телефоне с production package запускай только:

```bash
tool/run_android_integration.sh <device-id>
```

Прямой `flutter test -d <device> integration_test/...` запрещён: teardown
может удалить production package и локальные данные.

## Следующая задача

Продолжай P2 в таком порядке:

1. Заверши CR-08 как отдельную schema/DTO миграцию: сначала инвентаризация
   реально используемых полей каждого exercise, typed DTO/mappers на data
   boundary, backward-compatible чтение schema v1 и fixtures старых курсов.
   Не меняй backend/cache schema без доказанной необходимости и migration plan.
2. CR-13: продолжи UI → Controller/ViewModel → Repository/Service. Начни с
   Import, затем общего Course/Exercise loader; новый state-management
   framework не добавляй.
3. CR-14: перенеси TTS в cache directory, введи bounded size/TTL или LRU,
   atomic write и тесты eviction/corruption.
4. CR-15: заверши localization и TalkBack/font scale 200%/touch target audit.
5. CR-16: major dependencies обновляй по одному семейству с changelog,
   migration notes и полным gate после каждого семейства.
6. После стабилизации добавь privacy-safe telemetry для cold start, import
   duration, cache hit, parse failure и crash-free users — только после
   отдельного решения о провайдере/consent.

Отдельные остаточные риски:

- cross-device conflict resolution остаётся additive merge; revision/updatedAt
  потребует нового совместимого backend contract;
- force-device backend операция не транзакционна: при промежуточном сбое может
  удалить часть старых записей, честно вернув 503; повтор безопасен;
- backend security review и Firestore rules audit ещё нужны до публичного
  релиза;
- release versionCode всё ещё 10, а архивные APK/AAB pre-P0 публиковать нельзя.

## Полный gate следующей работы

```bash
cd /home/igor/project/exam_trainer
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter test --coverage
git diff --check

cd /home/igor/project/exam-trainer-api
PYTHONPATH=/tmp/exam-api-test-deps python3 -m unittest discover -s tests -p 'test_*.py'
python3 -m py_compile main.py firestore_client.py firebase_auth.py
git diff --check
```

Если `/tmp/exam-api-test-deps` отсутствует, создай временное venv/target из
`requirements.txt`; не добавляй окружение в репозиторий.

Для release проверь APK через `apksigner`/`aapt2` и отдельно fail-closed без
signing-файлов, не печатая `key.properties` или passwords. Просмотри полный
diff обоих репозиториев. Обнови `CODE_REVIEW_2026-07-15.md`, этот handoff и
канонический `PRODUCT_PLAN.md`, сохраняя историю и честные partial statuses.
После успешной проверки сохрани 2–3 предложения в Hermes Memory с префиксом
`[project:/home/igor/project/exam_trainer]`.

Не коммить, не push и не деплой без актуального разрешения пользователя.
