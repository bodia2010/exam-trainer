# Передача работы следующему AI-агенту

Обновлено 15 июля 2026 года после сессии независимой перепроверки, которая
устранила REQUEST CHANGES по TTS-конкурентности, lifecycle
`DialogueAudioPlayer` и неполноте CR-14/CR-08 — поверх предыдущей сессии,
завершившей CR-08 typed DTO migration и продвинувшей CR-13/CR-14/CR-15/CR-16.
Этот файл — готовый prompt; его можно передать агенту целиком.

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
2. До записи кода найди Hermes Memory по ключам `Exam Trainer P2 CR-08 typed
   DTO variant loader TTS cache CR-13 CR-15 CR-16 dependencies`.
3. Проверь `git status --short`, последние commits и remote обеих веток.
   Не перезаписывай пользовательские изменения; `.idea/` backend не трогай.
4. Для definitions/callers/callees/impact используй CodeGraph, для literal
   search — `rg`. Если индекс отсутствует, не запускай init без разрешения.
5. Проверяй замечания по реальному коду. После каждого изменения добавляй
   тест; не делай полную архитектурную перепись.
6. Не деплой backend/Play artifact и не запускай платный Gemini/live PDF parse
   без отдельного разрешения.

## Проверенный baseline

P0 (CR-01—CR-06) и P1 (CR-07, CR-09—CR-12 закрыты; CR-08 на тот момент был
частичным) описаны в предыдущих разделах `CODE_REVIEW_2026-07-15.md` и не
повторяются здесь. Эта сессия добавила:

- **CR-08 закрыт.** Введены typed immutable DTO для всех 12 типов
  упражнений (`lib/models/exercises/*.dart`) с defensive, type-checked
  parsing (`is`-проверки, а не `as T?` cast — неправильный тип поля
  деградирует к безопасному значению, а не бросает `TypeError`). Все 6
  exercise screens читают DTO вместо `Map<String,dynamic>`. Старый (v1, без
  `schema_version`) и текущий формат курса читаются одним и тем же кодом;
  backend/cache schema не менялись. 27 новых тестов (DTO + legacy-migration
  fixture на 10 типов секций).
- **CR-13 продвинут.** Новый `lib/ui/features/exercise/variant_loader.dart`
  (`loadVariant<T>`) убрал ~120 строк дублированного boilerplate загрузки
  курса/варианта из 6 экранов. Остальные экраны (кроме Import и exercise
  loading) всё ещё обращаются к сервисам напрямую — это осознанно оставлено
  на следующую сессию, не переписано вслепую.
- **CR-14 закрыт.** TTS-кэш перенесён в `getApplicationCacheDirectory()`
  (был в `Documents`), добавлены лимит 200 MiB, LRU-эвикция по `mtime`,
  атомарная запись через `.tmp`+rename, sweep осиротевших `.tmp`. 6 новых
  тестов.
- **CR-15 частично.** `dialogue_audio_player.dart` (3 экрана) полностью
  локализован; попутно найден и исправлен CR-11-класса баг (сырой
  `e.toString()` в поле ошибки, просто никогда не выводился на экран).
  `Semantics`/touch-target добавлены в `_AnswerButton`, `_mcOption`,
  `_OptionTile`, `_ScoreChip` (liveRegion). **Не сделано**: `DropdownButton`
  в `_GapWidget` (обе sprachbausteine-экрана) не объявляет, к какому gap он
  относится; реальный TalkBack/font-scale 200% прогон на устройстве не
  проводился (не было подключённого устройства). CR-15 не закрыт полностью.
- **CR-16 частично.** `firebase_auth`/`firebase_core`/`uuid` подняты в
  рамках существующих caret-констрейнтов (`flutter pub upgrade`, без правки
  `pubspec.yaml`). Major-апгрейды (`go_router` 13→17, `google_fonts` 6→8,
  `device_info_plus` 10→13) оценены, но НЕ выполнены — слишком высокий блаcт
  радиус для одной сессии без выделенного smoke-прогона на каждое семейство.
  `file_picker` **нельзя** обновлять без отдельной проверки: коммит
  `c53c20c` зафиксировал, что 11.x ломает сборку (Kotlin/AAR
  class-not-found) с текущим toolchain, а 10.3.11 retracted с pub.dev — пин
  на точную `10.3.10` в `pubspec.yaml` намеренный. Release build также
  предупредил, что `device_info_plus`/`file_picker` используют устаревший
  способ подключения Kotlin Gradle Plugin — будущий Flutter может перестать
  их собирать; ещё один аргумент делать апгрейд `device_info_plus` отдельной
  задачей с полным ручным тестом device-gate (CR-09/CR-10 полагаются на
  этот пакет).

**Сессия независимой перепроверки (тем же днём) добавила поверх этого:**
независимая проверка вернула REQUEST CHANGES по трём пунктам, все три
устранены:

- **Конкурентная запись TTS-кэша исправлена.** `TtsService.ensureAudio`
  раньше писал `<key>.mp3.tmp` без синхронизации — два параллельных запроса
  одной `DialogueLine` могли гонять один и тот же временный файл и падать
  с `PathNotFoundException` на `rename()`. Теперь `_pendingByKey`
  сериализует все операции (включая `forceRegenerate`) по ключу; запись
  атомарна как раньше, ошибка удаляет только свой `.tmp`. 4 новых теста
  (`group('concurrent ensureAudio calls')` в `test/services/tts_cache_test.dart`).
- **Lifecycle `DialogueAudioPlayer` исправлен.** Единый `_opToken`
  инвалидирует устаревшие async-цепочки `_start`/`_playFrom` после
  dispose/повторного запуска/regenerate; `_cycleSpeed` получил
  недостающую `mounted`-проверку после `await`; paused-состояние теперь
  озвучивается как `s.weiterhoeren`, а не `s.dialogAnhoeren`. 3 новых
  теста (`group('lifecycle')` в `test/widgets/dialogue_audio_player_test.dart`).
- **CR-14 доведён до полного закрытия.** Добавлен one-time best-effort
  cleanup унаследованного `Documents/tts_cache` (запускается при первом
  обращении к `TtsService._dir` за процесс). 4 новых теста
  (`group('legacy Documents/tts_cache cleanup')`).
- **CR-08 усилен.** `ExerciseQuestion.number` (и `hoeren_teil1`'s
  `RichtigFalschQuestion.number`/`MultipleChoiceQuestion.number`) — ключ
  answer-карт во всех exercise screens — раньше дефолтился в `0` при
  отсутствии/неверном типе, из-за чего два вопроса без номера молча
  схлопывались в один (регрессия «два вопроса → №0»). Теперь бросает
  `ExerciseSchemaException` (перехватывается существующим `loadVariant()` →
  error UI, не spinner) и проверяется на уникальность. `section_list_screen.dart`/
  `probe_pruefung_screen.dart` проверены и признаны безопасными как есть
  (навигация/подсчёт по индексу списка, не по JSON-полю — задокументировано
  в CODE_REVIEW, не переведены на typed DTO, так как это не минимальное
  изменение и не устраняет реальный дефект). Legacy-fixture расширена с 10
  до всех 12 типов упражнений. 4 новых/изменённых теста в
  `test/models/exercises/exercise_dto_test.dart`.

Подробности каждого пункта, включая найденный попутно баг с
`Future.whenComplete().ignore()`, — в `CODE_REVIEW_2026-07-15.md`, раздел
«Независимая перепроверка P2 (CR-08/CR-14): устранение блокирующих
замечаний».

Последние фактические gates (после сессии перепроверки):

- `dart format --output=none --set-exit-if-changed .` — pass;
- `flutter analyze` — pass, "No issues found!";
- `flutter test` — 248/248 (было 233 до этой сессии, 191 до P2);
- `flutter test --coverage` — 2334/4703, 49,63%;
- backend — 72/72 (не менялся этим агентом, 0 собственного diff),
  `py_compile` pass (проверено во временном venv, не добавленном в
  репозиторий); backend-репозиторий содержит предсуществующий
  незакоммиченный diff `PRODUCT_PLAN.md` от предыдущей сессии плюс правки
  этой сессии поверх него — оба вместе составляют один логичный
  backend-коммит документации;
- production release APK **не пересобиралась** в сессии перепроверки —
  изменения ограничены Dart-кодом клиента и тестами, release-конфигурация
  не менялась;
- `git diff --check` — pass на обоих репозиториях;
- device integration smoke — **выполнен**: `RFCY51N8PEK` (Samsung
  SM-S938B) был подключён, `tool/run_android_integration.sh RFCY51N8PEK`
  прошёл 1/1 (`pdf_course_smoke_test.dart`), production package остался
  установлен, integration package удалён. Этот smoke общий (PDF → курс →
  упражнение), не специфичен для TTS/audio — выделенного integration-теста
  на аудио-воспроизведение в репозитории нет.

`git status --short` покажет изменённые/новые файлы; сверься с
`CODE_REVIEW_2026-07-15.md`, разделы «P2 (CR-08 завершение, CR-13—CR-16)» и
«Независимая перепроверка P2 (CR-08/CR-14): устранение блокирующих
замечаний», для точного списка.

Ранее зафиксированные коммиты остаются валидным P0/P1 baseline:

- Flutter branch `phase5-account-deletion`, P1 implementation `c61fa88`,
  P1 docs `56a9603`;
- backend branch `phase3-2-promptfoo-gate`, contract commit `5495185`;
- P0 baseline Flutter — `276afdb`.

Эта сессия (независимая перепроверка P2, TTS-конкурентность/lifecycle/CR-08)
закоммичена как `be13141` (branch `phase5-account-deletion`).

На телефоне с production package запускай только:

```bash
tool/run_android_integration.sh <device-id>
```

Прямой `flutter test -d <device> integration_test/...` запрещён: teardown
может удалить production package и локальные данные.

## Следующая задача

1. **CR-13**: продолжи UI → Controller/ViewModel → Repository/Service для
   оставшихся экранов (помимо Import и exercise loading, который уже сделан
   в этой сессии). Не добавляй новый state-management framework.
2. **CR-15**: добавь per-gap accessible label в `DropdownButton`
   (`_GapWidget` в `sprachbausteine_exercise_screen.dart` и
   `sprachbausteine2_exercise_screen.dart`) — например, обернуть в
   `Semantics(label: 'Lücke ${gapIndex + 1}')`. Проведи реальный TalkBack и
   font-scale 200% прогон на физическом устройстве и зафиксируй результат
   честно (pass/fail/частично). Устройство (Samsung SM-S938B) было
   доступно в конце сессии независимой перепроверки, но эта задача была
   вне её объёма — если оно снова подключено, это первый кандидат для
   реального прогона, а не откладывания дальше.
3. **CR-16**: обновляй `go_router`, `google_fonts`, `device_info_plus` по
   одному семейству в отдельной ветке, читая changelog/migration notes
   перед началом, и прогоняя полный gate (включая device smoke, если есть
   подключённое устройство) после каждого. `file_picker` НЕ трогай без
   отдельной проверки, что Kotlin/AAR-проблема из `c53c20c` действительно
   решена в новой версии на актуальном Flutter toolchain — сначала
   попробуй в изолированной ветке/копии, не в основной работе.
4. После стабилизации добавь privacy-safe telemetry для cold start, import
   duration, cache hit, parse failure и crash-free users — только после
   отдельного решения о провайдере/consent.

Отдельные остаточные риски (не изменились с прошлой сессии):

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
python3 -m unittest discover -s tests -p 'test_*.py'
python3 -m py_compile main.py firestore_client.py firebase_auth.py
git diff --check
```

Backend-репозиторий сейчас не содержит готового venv с `flask` и остальными
зависимостями из `requirements.txt` — создай временное venv в scratchpad
(`python3 -m venv ...`, `pip install -r requirements.txt`), не добавляй его в
репозиторий.

Для release проверь APK через `apksigner`/`aapt2` и отдельно fail-closed без
signing-файлов, не печатая `key.properties` или passwords. Просмотри полный
diff обоих репозиториев. Обнови `CODE_REVIEW_2026-07-15.md`, этот handoff и
канонический `PRODUCT_PLAN.md`, сохраняя историю и честные partial statuses.
После успешной проверки сохрани 2–3 предложения в Hermes Memory с префиксом
`[project:/home/igor/project/exam_trainer]`.

Сессия независимой перепроверки (2026-07-15, TTS-конкурентность/lifecycle/
CR-08) получила явное разрешение пользователя коммитить и push после
полного успешного gate — и сделала это (см. commit hash выше). Для
следующей сессии: не коммить, не push и не деплой без свежего актуального
разрешения пользователя, если явно не переговорено иначе.
