# Передача работы следующему AI-агенту

Обновлено 16 июля 2026 года после продолжения CR-15 (локализованные gap
Semantics, 48 dp, 200%-layout и Android smoke) и ЧЕТВЁРТОГО раунда независимой
перепроверки, устранившего ownership-дефекты typed lease и `clearCache`,
поверх третьего раунда, устранившего нарушенную гарантию возвращаемого пути в
`TtsService.ensureAudio` (HIGH: `exclude`-параметр защищал файл только от
ЕГО СОБСТВЕННОГО eviction-прохода, но не от более раннего прохода
ДРУГОГО cache key) и смежный race двух `_playFrom` с одним `_opToken` в
`DialogueAudioPlayer` (устаревший `_jumpTo` мог зарегистрировать
completion-listener после более нового) — поверх второго раунда
(concurrent LRU over-eviction, ложное `playing`-состояние при сбое
`AudioPlayer.play()`), который сам был поверх первого раунда
(TTS-конкурентность одного ключа, lifecycle-токены, CR-08 identification
fields), который был поверх сессии, завершившей CR-08 typed DTO migration
и продвинувшей CR-13/CR-14/CR-15/CR-16. Этот файл — готовый prompt; его
можно передать агенту целиком.

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
- **CR-15 частично (исторический статус до продолжения 16 июля; актуальный
  статус ниже в разделе «Продолжение CR-15»).**
  `dialogue_audio_player.dart` (3 экрана) полностью
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
`CODE_REVIEW_2026-07-15.md`, разделы «P2 (CR-08 завершение, CR-13—CR-16)»,
«Независимая перепроверка P2 (CR-08/CR-14): устранение блокирующих
замечаний» и «Второй раунд независимой перепроверки P2 (CR-14): concurrent
eviction и DialogueAudioPlayer play-error state», для точного списка.

Ранее зафиксированные коммиты остаются валидным P0/P1 baseline:

- Flutter branch `phase5-account-deletion`, P1 implementation `c61fa88`,
  P1 docs `56a9603`;
- backend branch `phase3-2-promptfoo-gate`, contract commit `5495185`;
- P0 baseline Flutter — `276afdb`.

Эта сессия (независимая перепроверка P2, TTS-конкурентность/lifecycle/CR-08)
закоммичена как `be13141` (branch `phase5-account-deletion`).

### Второй раунд независимой перепроверки — TTS concurrent eviction (HIGH) и DialogueAudioPlayer play-error state (MEDIUM)

Независимая проверка запушенных `be13141`/`85586c8` нашла два новых
дефекта, которые первый раунд не поймал:

- **HIGH — конкурентная LRU-эвикция.** `_enforceCacheBudget()` вызывалась
  независимо каждым commit'ом; два одновременных commit'а РАЗНЫХ ключей
  могли оба увидеть один и тот же «over budget» снимок каталога и оба
  удалить файл — иногда оставляя кэш вообще пустым там, где нужно было
  удалить ровно один файл. Исправлено новой глобальной очередью
  `_evictionChain` (`_commitAndEnforceBudget`), отдельной от per-key
  `_pendingByKey`: сериализует commit+evict хвост ЛЮБОГО ключа (синтез
  по-прежнему параллелен), с параметром `exclude`, гарантирующим, что
  `ensureAudio()` никогда не возвращает путь, который ЕГО ЖЕ собственный
  eviction-проход только что удалил. 2 новых теста
  (`group('concurrent LRU eviction across different keys')` в
  `test/services/tts_cache_test.dart`), проверены как настоящий
  regression (временный откат воспроизвёл падение 6/6 прогонов).
- **MEDIUM — ложное `playing`-состояние.** `_playFrom()` переводил
  `_state` в `playing` до `_player.play()`; сбой `play()`/
  `setPlaybackRate()` молча проглатывался (или вообще не был обёрнут для
  `setPlaybackRate`), оставляя виджет со внешне «играющим» баром без
  звука. Исправлено: оба вызова в одном try/catch → `_PlayerState.error`
  (generic-локализованный, без raw exception) при актуальной операции,
  тихий возврат при устаревшей/disposed. `pause`/`resume`/`stop`/`seek`
  тоже получили обработку unhandled async exceptions. Добавлен
  минимальный injectable `AudioPlayerAdapter` (`@visibleForTesting
  debugPlayerFactory` на `DialogueAudioPlayer`, `null` в проде →
  настоящий `AudioPlayer`) — впервые позволяет тестам реально достигать
  `playing`/`paused` состояний, в обход `audioplayers`' platform channels
  (не замоканы в `flutter test`). 5 новых тестов
  (`group('AudioPlayer failure handling')` в
  `test/widgets/dialogue_audio_player_test.dart`), один проверен как
  настоящий regression тем же способом.

Полные детали (модель синхронизации, гарантии, обработка ошибок) — в
`CODE_REVIEW_2026-07-15.md`, раздел «Второй раунд независимой
перепроверки P2 (CR-14): concurrent eviction и DialogueAudioPlayer
play-error state».

Gates этого раунда: `flutter test` 255/255 (было 248, +7); coverage
2423/4746 (51,05%, было 49,63%); `flutter analyze`/`dart format` чистые;
backend 72/72 + `py_compile`, 0 diff кодом (только `PRODUCT_PLAN.md`
доку-обновлён); `git diff --check` чист оба репо; device smoke
`tool/run_android_integration.sh RFCY51N8PEK` 1/1 на Samsung SM-S938B,
production package (`versionCode=10`, `versionName=1.0.0`) цел,
integration package удалён.

**CR-14 теперь честно закрыт** — оба независимо найденных дефекта
исправлены и протестированы как regression, не просто задокументированы.

Эта сессия закоммичена как `ee5c25a` (branch `phase5-account-deletion`).

### Третий раунд независимой перепроверки — нарушенная гарантия возвращаемого пути (HIGH) и `_playFrom` seq-race (MEDIUM), 16 июля 2026

Независимая проверка запушенных `ee5c25a`/`ecc4783` нашла, что заявление
«CR-14 закрыт» из второго раунда было преждевременным: `exclude:
justCommittedPath` защищал файл только от eviction-прохода СОБСТВЕННОЙ
операции — более ранний проход другого cache key мог увидеть файл более
поздней операции (уже на диске, ещё не в очереди) и удалить его, пока та
операция ждала своей очереди. Детерминированный репро (два параллельных
`ensureAudio()` разных ключей, лимит 1000Б, проверка `File(path).exists()`
сразу по резолву каждого Future) стабильно давал `[false, true]` —
нарушение единственной гарантии всей этой синхронизации. Существовавший
regression-тест `test/services/tts_cache_test.dart` при этом требовал
`existsA != existsB` сразу после `Future.wait` — то есть сам кодировал
баг как ожидаемое поведение.

**Исправление**: refcounted pin/lease-модель. `TtsService._pinnedPaths`
(`Map<String, int>`) — глобальный набор путей, «сейчас у кого-то на
руках», а не единичный `exclude` конкретного прохода. `_pin(path)`
инкрементирует синхронно, без единого `await` между моментом, когда файл
становится валидным (успешный `rename()` или подтверждённый cache-hit),
и инкрементом — тот же приём, что второй раунд уже применял к «своему»
проходу, теперь распространён на ВСЕ проходы разом:
`_enforceCacheBudget()` пропускает любой запиненный путь как кандидата
на удаление, кем бы ни был запущен конкретный проход. Снятие pin —
ТОЛЬКО явное, через новый публичный `releasePaths(Iterable<String>)`;
автоматического снятия в `finally` нет намеренно — оно бы race'ило
собственную continuation вызывающей стороны (microtask ordering: `finally`
внутри async-функции выполняется раньше, чем `await`/`.then()` у
вызывающего успевает получить управление). Пока путь удерживается,
эвикшн временно не может привести кэш под лимит — задокументированный,
не бесконечный trade-off: `releasePaths()` детерминированно запускает
отложенный eviction-проход, как только последний держатель освобождает
путь.

Единственный реальный потребитель, `DialogueAudioPlayer`, обновлён
вызывать `releasePaths()` на каждой точке, где он перестаёт использовать
путь: нормальное завершение диалога, ошибка синтеза, ошибка
воспроизведения (плюс теперь best-effort `_player.stop()` — раньше
`setPlaybackRate()`-сбой после успешного `play()` оставлял реальное
аудио играть без надзора под error UI), `stop()`, `regenerate()` (release
ДО `clearCache`, не после), `dispose()` (плюс исправлен
самостоятельный баг: `_player.dispose()` — `Future<void>` — вызывался
без `await`/обработки, сбой становился unhandled async exception) и
устаревшая операция, заметившая расхождение `_opToken`.

Попутно найден и исправлен смежный баг: `_jumpTo()` не бумпает `_opToken`
(две реплики в транскрипте — одна операция), поэтому существовавшая
`token != _opToken`-проверка не ловила случай, когда более СТАРЫЙ
(по вызову) `_playFrom` резолвился ПОСЛЕ более нового и регистрировал
СВОЙ completion-listener поверх уже зарегистрированного (переприсваивание
`_onCompleteSub` не отменяет предыдущую подписку broadcast-стрима — обе
остаются активными). Добавлен независимый `_playSeq`-счётчик,
сверяемый на каждой точке после `await` внутри `_playFrom` и его
completion-listener.

11 новых/переписанных тестов (`tts_cache_test.dart`: 3 теста в группе
`concurrent LRU eviction across different keys`, переписаны 2
single-key eviction-теста на release-aware; `dialogue_audio_player_test.dart`:
новая группа `lease release`, 6 тестов, включая обязательный
"AudioPlayerAdapter.dispose() failing" тест и `_playSeq`-regression с
новым `gateNextPlay` fake-seam). Все три ключевых блока (cross-key
eviction pin, `_playSeq`) проверены как настоящий regression через
временный откат — оба воспроизвели исходное падение 100% прогонов,
восстановление исправления — 100% зелёных.

Полные детали (точная модель, гарантии, все тесты, доказательства
регрессии) — в `CODE_REVIEW_2026-07-15.md`, раздел «Третий раунд
независимой перепроверки P2 (CR-14): нарушенная гарантия возвращаемого
пути и lease-lifecycle DialogueAudioPlayer».

Gates этого раунда: `flutter test` 261/261 (было 255, +6); coverage
2510/4786 (52,44%, было 51,05%); `flutter analyze`/`dart format` чистые;
backend 0 diff кодом (не трогался); `git diff --check` чист оба репо;
device smoke `tool/run_android_integration.sh RFCY51N8PEK` 1/1 на
Samsung SM-S938B, production package (`versionCode=10`, `versionName=1.0.0`)
цел, integration package удалён.

**CR-14 теперь закрыт с доказанной гарантией возвращаемого пути** —
третий независимо найденный дефект в этом же коде исправлен и
протестирован как regression. Остаточные риски: (1) pin/lease- и
`_playSeq`-синхронизация по-прежнему проверены только host-side с
фейковыми зависимостями, без выделенного device-теста под реальной
нагрузкой; (2) модель полагается на дисциплину каждого вызывающего
`ensureAudio()` — если появится второй реальный потребитель помимо
`DialogueAudioPlayer`, он обязан сам вызывать `releasePaths()`, это не
enforced на уровне типов.

Эта сессия закоммичена как `a970ca0` (branch
`phase5-account-deletion`) — см. `CODE_REVIEW_2026-07-15.md` для точного
hash после docs follow-up коммита.

### Четвёртый раунд независимой перепроверки — ownership-safe typed lease и clearCache, 16 июля 2026

Проверка `a970ca0` воспроизвела ещё два дефекта: строковый
`releasePaths()` не был идемпотентен на уровне владельца (два владельца
одного пути, двойной release A снимал pin B), а `clearCache()` удалял общий
путь даже при активном lease другого плеера. Исправление меняет публичный
результат `ensureAudio()` на `TtsAudioLease`: каждый вызов получает уникальный
ownership id, `lease.release()` идемпотентен именно для этого объекта, путь
доступен как `lease.path`. `DialogueAudioPlayer` — единственный production
caller по CodeGraph и literal search — полностью переведён на объекты lease.

Cache hit/touch+lease, commit+eviction, release eviction и `clearCache`
сериализованы общей `_cacheTransactionChain`; сеть для разных ключей остаётся
параллельной. `clearCache` пропускает пути, которыми ещё владеет кто-либо
другой. Две новые регрессии `ownership-aware leases` доказывают двойной
release и shared-clear сценарии; весь TTS cache suite мигрирован на typed API.
Gate: `flutter analyze` clean, `flutter test` 263/263,
`flutter test --coverage` 2521/4799 (52,53%), фокусные TTS/player тесты
35/35; backend 72/72 + `py_compile`; release APK собран. Device smoke
`tool/run_android_integration.sh RFCY51N8PEK` прошёл 1/1 на Samsung
SM-S938B, production package 1.0.0+10 сохранился, integration package
удалён. Gradle предупреждает о будущей Built-in Kotlin миграции
`device_info_plus`/`file_picker` — учитывать в CR-16. Реализация четвёртого
раунда: Flutter `4d1c668`, backend docs `d89e8cf`.

CR-14 закрыт по всем четырём найденным раундам. Остаточный риск: real-device
нагрузочный TTS/audioplayers тест отсутствует; новый caller всё ещё обязан
вызвать `lease.release()`, но повторным release больше нельзя освободить
чужое владение.

### Продолжение CR-15 — gap Semantics и 200% text scale, 16 июля 2026

Оба Sprachbausteine dropdown теперь объявляют реальный номер PDF-пропуска
через локализованный `S.lueckeAuswaehlen()` (de/ru/uk/en), сохраняют нативные
tap/value Semantics и имеют цель минимум 48 dp. Teil 1 хранит исходный номер
отдельно от внутреннего `gapIndex`: не заменяй его на ошибочный `index + 1`.
Scale-aware selected item + отдельная ширина меню устранили подтверждённые
overflow +69/+27 px при 200%; `Text.rich` наследует `TextScaler`.

Добавлено 6 host tests и backend-free Android smoke обоих экранов. Gate:
269/269, coverage 2829/4822 (58,67%), analyze/format чисты, release APK
собран; safe device runner: PDF 1/1 + CR-15 1/1 на SM-S938B. Integration
package удалён. Production package до запуска уже отсутствовал, поэтому этот
конкретный прогон не доказывает его сохранность. Автоматизированы точный 200%
и Semantics tree/actions; ручное прослушивание TalkBack, high contrast и
keyboard navigation остаются честно непроверенными. Реализация: Flutter
`3bb1ec3`; backend plan docs `e763c08` (backend-код не менялся).

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
2. **CR-15 manual audit**: попроси пользователя включить TalkBack и вручную
   подтвердить фактическое произношение/порядок фокуса на обоих экранах;
   отдельно проверить high contrast и keyboard navigation. Не меняй
   accessibility settings телефона через ADB.
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

Обе сессии независимой перепроверки (2026-07-15: первая —
TTS-конкурентность/lifecycle/CR-08; вторая — concurrent eviction/
play-error state) получили явное разрешение пользователя коммитить и push
после полного успешного gate — и сделали это (см. commit hash'и выше). Для
следующей сессии: не коммить, не push и не деплой без свежего актуального
разрешения пользователя, если явно не переговорено иначе.

### Последний device-fix — startup redirect overlay, 16 июля 2026

Новая установка на Samsung SM-G985F зависала на branded preload: login уже
разрешался GoRouter внутри, но внешний overlay продолжал видеть исходный `/`.
`RouterStartupOverlay` теперь слушает `routerDelegate.currentConfiguration`;
Home по-прежнему снимает overlay только после загрузки библиотеки. Настоящий
GoRouter regression test покрывает управляемый `/` → `/login` redirect.

Проверено: format/analyze чисты, 271/271 tests, coverage 2849/4841 (58,85%),
двойной cold launch исправленного production APK на том же телефоне открыл
Login без crash. Артефакт `build/app/outputs/flutter-apk/app-production-release.apk`:
59 513 582 bytes, SHA-256
`f19718cb60597e1a707bbddbad8f281313c6c940170a55ad16ddef490674b460`.

Release после integration/coverage собирай через
`tool/build_android_release.sh`: Flutter может оставить игнорируемый dev
`GeneratedPluginRegistrant.java` с `integration_test`, а скрипт удаляет
только этот stale generated-файл перед обычным release build. Не добавляй
registrant в git и не переноси `integration_test` в production dependencies.

На SM-G985F safe runner дополнительно прошёл PDF flow 1/1 и accessibility
flow 1/1; isolated integration package удалён, production package сохранён.

### Последний TTS-fix — Andrea не должна звучать мужским голосом

> Исторический промежуточный фикс; заменён robust rollout ниже. Не возвращай
> backend-списки конкретных имён.

`TtsService` теперь извлекает имя из самопредставлений без `Herr/Frau`
(`hier ist/spricht`, `ich bin`, `mein Name ist`). Для «Hallo, hier ist Andrea
Faber» speaker равен `Andrea Faber`, поэтому старый empty-speaker cache key не
используется. Backend `tts.py` относит `andrea` к женскому пулу; `/api/tts`
совместим и не менялся.

Gate: Flutter 274/274, coverage 2851/4843 (58,87%), backend 73/73. Чистый
production APK установлен на SM-G985F, SHA-256
`16bcb436ec325cf231d7ff6f3f00a61dcc13e8282be04651bd8710d129968e78`.
Устройство без авторизованного курса подтвердило установку/cold launch, но
реальное произношение Andrea должен повторно прослушать пользователь на
телефоне с этим курсом.

`tool/build_android_release.sh` намеренно делает полный `flutter clean` +
`flutter pub get`: не ослабляй это до incremental release без доказательства,
поскольку stale build сохранял прежний APK/hash после Dart-изменений.

### Последний TTS-rollout — robust voice_gender, 16 июля 2026

Одноразовая Andrea/name-coupling заменена staged compatible контрактом.
Backend `/api/tts` принимает optional `voice_gender` (`female`/`male`/
`unknown`), где missing/`unknown` сохраняют совместимость, а explicit
`female`/`male` override'ят эвристику явной роли. Parser/schema могут отдавать
optional nested `metadata.voice_gender` и `metadata.speaker_voice_genders[]`;
span resolution сохраняет только валидные hints. Backend name lists удалены;
не добавляй одноразовые имена обратно. Неуверенная parser metadata должна быть
`unknown`, ручной override остаётся окончательным выбором пользователя.

Flutter добавил `VoiceGender`/metadata parsing, v2 gender-aware TTS cache keys,
`voice_gender` request field for known genders, stable recording IDs для
Telefonnotiz/Hören Teil 1/universal Hören, UID-isolated
`VoicePreferenceRepository` with latest-wins writes and account-deletion
cleanup. Signed-out режим не создаёт общий `anonymous` namespace; ключи
preference дополнительно изолированы по course ID и позиции записи, а
non-ASCII labels защищены digest. Parse cache version — `v37`.
`DialogueAudioPlayer` теперь показывает localized
Automatic/Female/Male controls (per speaker for dialogues), сохраняет manual
overrides, reparses lines on metadata/recording/override changes, stops audio,
releases typed leases, rejects stale operations and never autoplays after a
switch.

Последние gates: Flutter format/analyze clean, `flutter test` 299/299,
coverage 3207/5229 (61.33%), backend 86/86 + `py_compile`, `git diff --check`
clean. Safe PDF integration прошёл на `192.168.1.42:33233`; production APK
собран, установлен и cold-launched без crash, SHA-256
`eb71a83f38b9f8f5ee1531ab4ee4c42192341ac407276dad7a5c5a2bc91adf7f`.
На телефоне Login, поэтому manual TTS listening после авторизации ещё нужен.
Backend production deploy и live Gemini parse не выполнялись.
