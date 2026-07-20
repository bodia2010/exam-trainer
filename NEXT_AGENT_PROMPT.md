# Передача работы следующему AI-агенту

Обновлено 19 июля 2026 года. Текущий этап — Premium semantic remediation v38;
обязателен dual-format/cache rollout. Ранее файл был обновлён после CR-15
(локализованные gap
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
2. **CR-16**: обновляй `go_router`, `google_fonts` по
   одному семейству в отдельной ветке, читая changelog/migration notes
   перед началом, и прогоняя полный gate (включая device smoke, если есть
   подключённое устройство) после каждого. `file_picker` НЕ трогай без
   отдельной проверки, что Kotlin/AAR-проблема из `c53c20c` действительно
   решена в новой версии на актуальном Flutter toolchain — сначала
   попробуй в изолированной ветке/копии, не в основной работе.
3. После стабилизации добавь privacy-safe telemetry для cold start, import
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

### Device follow-up: false narrator `Frau Zimmer`

После production backend/cache v37 rollout пользователь подтвердил правильный
source contract для Hören Teil 4, но нашёл Flutter-баг: №40 отображался как
`Frau Zimmer`, потому что `_detectNarrator()` принимал упомянутую секретаря за
говорящую. Исправлено без name lists: gendered narrator распознаётся только в
self-introduction в начале монолога. Regression test добавлен; analyze и
300/300 Flutter tests зелёные.

Для повторного device-test обязательно удалить старый локальный курс и
импортировать PDF заново: `CourseStorage.loadAll()` не заменяет существующий
local course новым Redis cache entry. Voice controls должны быть `Auto`; old
MP3 можно удалить Android action `Clear cache`. Ожидание: №38 female, №39 male,
№40 female и без speaker label `Frau Zimmer`.

### Device follow-up: playback after transcript collapse

В universal Hören Teil 2–4 `_TextCard` раньше условно удалял
`DialogueAudioPlayer` при collapse, поэтому `dispose()` останавливал звук.
Теперь весь detail-блок скрывается через `Visibility(maintainState: true)`:
звук продолжается, карточка не занимает лишнее место, вопросы доступны.
Regression test `test/screens/universal_audio_collapse_test.dart` фиксирует
идентичность State до/после collapse. Hören Teil 1 и Telefonnotiz не менялись.

### Account session actions follow-up — 17 июля 2026

В рабочем дереве есть незакоммиченный Flutter diff, добавляющий в профиль
локализованные действия `Abmelden / Sign out` и `Konto löschen / Delete
account`. Logout использует `AuthService.signOut()`, после успеха переходит на
`/login`, а ошибка показывает локализованный snackbar без raw exception.
Добавлен widget test `test/screens/account_actions_test.dart` для наличия и
callback-действий logout/delete во всех четырёх локалях. Это пока не является
проверенным release-коммитом: сначала проверь diff, формат/analyze/tests и
device flow, затем согласуй staging/commit.

Отдельного многосессионного switch-account picker нет и добавлять его без
продуктовой необходимости не следует. Сейчас смена UID должна работать через
logout → Login → вход другим Firebase UID. Перед закрытием follow-up проверь:

1. Успешный logout очищает Firebase/Google session и открывает `/login`.
2. Ошибка logout остаётся конечным локализованным состоянием и не выполняет
   неожиданную навигацию.
3. После входа другим UID не видны локальные курсы, favorites и voice
   preferences прежнего UID; account deletion cleanup/outbox guarantees не
   регрессировали.
4. Widget/integration tests и device smoke подтверждают logout, delete
   confirmation и UID switch. Не путай callback-тест с доказательством
   реального Firebase session transition.

Не перезаписывай пользовательский рабочий diff. Не коммить, не push и не
деплой без свежего явного разрешения пользователя.

### Device follow-up: account sheet visibility — 17 июля 2026

На Samsung SM-G985F подтверждено, что до layout-fix нижние account actions
обрезались viewport. `showModalBottomSheet` теперь использует
`isScrollControlled`, `SafeArea` и `SingleChildScrollView`; после установки
production APK на экране видны `Abmelden` и `Konto löschen`, а tap по
`Abmelden` реально переводит авторизованную сессию на Login.

Не считать Wi-Fi integration runner зелёным в этом раунде: ADB стал `offline`
во время teardown. Перед следующим smoke подключить устройство стабильно и
отдельно проверить production package guard.

### Sprachbausteine Teil 1 visual follow-up — 17 июля 2026

Не путать пользовательский экран с Beschwerde: скриншот с inline-пропусками
относится к `lib/screens/sprachbausteine_exercise_screen.dart`. Визуальный
фикс ограничен `_GapWidget`: компактный выбранный control с рамкой/стрелкой,
широкое меню для длинных слов, сохранены 48 dp и Semantics. `gapIndex`, исходный
PDF `questionNumber`, single-use word selection и scoring не менять.

Новый regression в `test/screens/sprachbausteine_gap_accessibility_test.dart`
проверяет 360×800/200%, длинный вариант, отсутствие layout exception, tap action
и полное слово в Semantics value. Перед публикацией нужен ручной device review
на 320/360 dp и TalkBack; CR-15 spoken-order/high-contrast/keyboard аудит всё
ещё не считается закрытым автоматически.

Ручная визуальная проверка inline baseline-варианта на телефоне пройдена
18 июля 2026: пользователь подтвердил «всё ок». Повторно переделывать layout
пропусков не нужно; сохранять alphabetic baseline, 48 dp, Semantics,
questionNumber/gapIndex, single-use selection и scoring.

### Следующая проверка: Lesen Teil 4 headings — 18 июля 2026

В рабочем дереве есть незакоммиченный фикс `universal_exercise_screen.dart`:
для `lesen_teil4` он превращает flattened-протокол в читаемую структуру
(метаданные отдельными строками, TOP 1/2/3 отдельными абзацами и жирным
акцентом). Эвристики намеренно не применяются к Hören/другим universal-секциям.
Тесты находятся в `test/screens/universal_exercise_screen_test.dart` и покрывают
метаданные, markdown/TOP, non-Lesen compatibility и 200% text scale.

Перед commit обязательно проверить весь diff вместе с уже незакоммиченным
Sprachbausteine baseline-изменением, прогнать format/analyze/full flutter test,
coverage и `git diff --check`, затем собрать production APK и при доступном
устройстве повторить визуальный Lesen Teil 4 smoke. Не перезаписывать и не
откатывать пользовательские изменения. После публикации обновить Hermes
Memory с префиксом `[project:/home/igor/project/exam_trainer]`.

### CR-13/CR-16 follow-up — 18 июля 2026

`FavoritesScreen` уже переведён на `FavoritesController` с terminal
error/retry state, stale-operation и dispose guard; тесты находятся в
`test/ui/features/favorites/` и `test/screens/favorites_screen_test.dart`.
Следующий CR-13 срез — `FavoriteButton`, затем при необходимости
`CourseScreen`/`SectionListScreen`; не делать массовую архитектурную перепись.

`device_info_plus` обновлён до `^12.4.0` и проверен analyze/tests/build в
изолированной копии. Не обновлять `13.x`, пока не решён конфликт `win32` с
намеренно закреплённым `file_picker 10.3.10`; KGP warning остаётся ожидаемым.

После обновления safe runner прошёл на SM-G985F: PDF 1/1 и Sprachbausteine
accessibility 1/1; production package сохранён, integration package удалён.
Свежий production APK установлен с `-r`. Не включать TalkBack/high contrast
через ADB — ручную проверку выполняет пользователь в системных настройках.

### CR-15 закрыт — 18 июля 2026

Пользователь вручную проверил TalkBack на production APK на Samsung SM-G985F
и подтвердил корректную работу. В сочетании с автоматическими Semantics,
48 dp, 200% text scale и device smoke CR-15 закрыт для целевой Android
touch/TalkBack-матрицы. Не возвращать его в active backlog без нового
конкретного дефекта. High contrast и внешняя клавиатура остаются optional
расширением матрицы, поскольку отдельно не проверялись.

### CR-13 FavoriteButton закрыт — 18 июля 2026

`FavoriteButtonController` уже вынесен в
`lib/ui/features/favorites/favorite_button_controller.dart`. Не возвращать
прямые async-вызовы `FavoritesService` в виджет: сохранять loading/ready/saving/
error, stale/dispose guards, disabled double-tap и локализованный retry. Девять
callers остаются API-совместимыми. Controller/widget tests покрывают error,
retry, stale load, double toggle и dispose; полный suite 319/319.

После этого `CourseScreen` тоже переведён на
`CourseScreenController` (`lib/ui/features/course/`). Сохраняй injected
`CourseLoader`, terminal not-found/error/retry UI, generation-token и
dispose guard. Regression tests покрывают success/not-found/error, stale
completion и dispose. Следующий небольшой CR-13 срез — `SectionListScreen`.

### CR-13 SectionListScreen закрыт — 18 июля 2026

`SectionListScreen` использует `SectionListController` с injected `CourseLoader`,
terminal states, retry, generation-token и dispose guard; смена `courseId` или
`sectionType` перезапускает загрузку. Добавлены controller tests на content/empty,
not-found/error, malformed variant, stale completion и dispose. Не возвращать
прямой async-вызов `CourseStorage` в экран.

### CR-13 ProbePruefungScreen закрыт — 18 июля 2026

Practice Exam использует `ProbePruefungController`; storage exception и malformed
variant завершаются error/retry, missing course — not-found, stale/dispose защищены.
Router listener больше не добавляется после dispose и проверяет mounted. Tests
покрывают terminal states, regeneration, stale completion и dispose.

### CR-16 dependency cleanup — 18 июля 2026

Неиспользуемый `google_fonts` удалён. Не добавлять его обратно без реального caller.
`go_router 13→17` обновлять только отдельной задачей с auth/device redirects и
integration smoke. `device_info_plus 13` пока конфликтует по `win32` с закреплённым
`file_picker 10.3.10`; file picker требует отдельного Android PDF-selection gate.

### Device limit lifecycle closed — 18 июля 2026

`DeviceLimitScreen` принимает injectable register/sign-out actions, ловит service
exceptions, не оставляет spinner и показывает локализованный error. Tests покрывают
registration и logout failure. Не удалять terminal error state при дальнейшей работе
с device-gate.

### CR-16 file_picker 11 заблокирован Android toolchain — 18 июля 2026

Сохранять точный pin `file_picker 10.3.10` и API `FilePicker.platform.pickFiles`.
v11.0.2 проходит host tests, но clean AGP9 release падает на отсутствующем
`FilePickerPlugin`: plugin ожидает built-in Kotlin, а host/остальные plugins ещё
используют legacy KGP compatibility. `android.builtInKotlin=true` отдельно также
не собирается. Не патчить pub cache и не брать beta 12; сначала мигрировать весь
Android host/plugins по официальному Flutter built-in Kotlin guide, затем повторить
release + реальный SAF picker smoke.
Изолированный pub resolver также доказал несовместимость стабильной пары:
`device_info_plus 13.2.0` требует `win32 ^6`, `file_picker 11.0.2` — `win32 ^5.9`.
Не форсировать dependency override; ждать совместимый stable file picker.

### CR-16 go_router 17 закрыт — 18 июля 2026

`go_router` обновлён до `^17.3.0`; migration source changes не потребовались.
Сохраняй sync Firebase redirect, background device gate, nested `/course` и
`/sprechen` маршруты. Router tests покрывают protected/public paths, auth return,
case sensitivity и nested deep-link. Следующим отдельным upgrade остаётся только
file picker/device-info стратегия.
Полный gate после обновления: 336/336, production APK и Android smoke на
`192.168.1.42:42673` зелёные; smoke запускался через fake fixture и не обращался
к production backend.

### Android SAF picker gate добавлен — 18 июля 2026

Для проверки настоящего системного выбора PDF используй только
`tool/run_android_saf_picker_smoke.sh <device-id>`. После открытия DocumentsUI
оператор вручную выбирает
`Downloads/ExamTrainerSafFixture/exam-trainer-saf-valid.pdf`. Тест использует
настоящий picker и validator, но offline fake import service: production backend,
Firebase и пользовательские курсы не затрагиваются.

Не заменять ручной выбор координатными `adb input tap` в постоянном runner:
DocumentsUI зависит от OEM, версии Android и локали. Runner обязан удалять
только integration package и собственную fixture-папку и сохранять production
package. На Samsung SM-G985F gate прошёл 1/1; invalid-signature и oversized PDF
продолжают проверяться более стабильными host regression-тестами.

### CR-13 exercise lifecycle follow-up — 18 июля 2026

Шесть exercise-экранов используют общий `VariantLoadGuard`: generation token,
`didUpdateWidget` для смены course/index/loader и dispose guard. Не удалять
сброс старого контента/ответов при смене варианта — это предотвращает показ
ответов предыдущего упражнения. Regression находится в
`test/screens/course_load_state_test.dart`; focused suite 26/26.

### CR-07 UID switch hardening — 18 июля 2026

`CourseStorage.loadAll()` проверяет captured UID после local/remote await,
до/после cloud merge write и в catch. Не возвращать прежний локальный список
при смене аккаунта. Три regression-теста находятся в
`test/services/course_storage_sync_outbox_test.dart`.

Это не закрывает межустройственный delete-vs-stale-upload конфликт. Не менять
backend вслепую: сначала зафиксировать продуктовую политику. Рекомендуемый
совместимый фундамент — additive revision metadata, persistent tombstone и
409 для stale operation; старый `courses` response и `ParsedCourse` сохранять.

### CR-07 delete-wins закрыт в коде — 18 июля 2026

Политика подтверждена пользователем: delete всегда побеждает stale upload;
re-import получает новый UUID. Flutter `CourseStorage` использует per-UID
revision/tombstone metadata и backward-compatible durable outbox с
`expectedRevision`. Opaque 409 разрешается через additive `GET.sync`: tombstone
терминально чистит stale local/favorites/op, live collision сохраняет локальную
копию под новым UUID, а недоступный/невалидный GET оставляет точный оригинал в
retry. Сохраняй UID guards и очистку active+`_corrupt` ключей при account delete.

Backend реализует Firestore CAS, permanent tombstones, 409 и 503-on-list-error;
старые `courses` и course JSON не изменены, legacy revision равен 0. Не удалять
tombstone и не разрешать legacy POST его перезаписать. Проверять совпадение
Firestore document id с JSON `course.id` и safe-ID на обеих сторонах. Код и
тесты готовы локально; production deploy не считать выполненным без отдельной
явной записи о deployment URL/smoke.

Последний локальный gate: Flutter 351/351, coverage 55.08%, backend 175/175,
format/analyze/py_compile/diff-check зелёные, production APK 59.9 MiB собран.
Device smoke не выполнен: `adb devices` не показал устройство. Следующий агент
не должен выдавать это за failure кода или за пройденный device gate.

Backend CR-07 уже в production: commit `2b553e6`, Vercel
`dpl_24YhsW6Qewyu3d6AHpDWQL29AWBV`, alias `exam-trainer-api.vercel.app`, Ready.
Safe OPTIONS/401 smoke пройден. Остался только authenticated device gate на
двух устройствах: загрузить/увидеть один тестовый курс, отключить сеть на B,
удалить на A, затем включить B и убедиться, что stale upload не воскресил курс.
Повторный импорт должен создать новый UUID и снова синхронизироваться.

Этот device gate выполнен 19 июля на SM-S938B + SM-G985F: offline-клиент после
reconnect удалил только tombstoned UUID, серверный курс не воскрес, re-import
того же PDF через cache создал новый UUID и появился на обоих телефонах. Не
повторять destructive smoke на пользовательском курсе без нового конкретного
дефекта. Pending stale POST→409 отдельно доказан host regression-тестами; device
gate честно не создавал искусственный production outbox через debug hooks.

### Premium full-PDF gate production test — 19 июля 2026

На Samsung SM-S938B (USB, RFCY51N8PEK), production APK versionCode 10, с
подтверждённым Premium badge и изначально пустой библиотекой: исходный
207-страничный flagship PDF (SHA-256
`53634b0c2c85cb2d6b9d5efabcf54a9a344ce5a7082e7a3b4cd1d0a5926149e9`) дал
production cache-hit, полный курс 12 типов/142 items. К файлу временно
добавлена нейтральная marker-страница (208 страниц, SHA-256
`77d38b429e996ae85ac30ee60a671fc812d626170b8fcef3fa34bd6ad333a7fc`); backend
логи подтвердили doc miss + discover miss при `tariff=premium`, то есть путь
неизвестного документа под Premium реально прошёл discovery+parse, а не кэш.

Discovery: 1 call, prompt 226009, candidates 10404, оценка $0.43265. Parse: 100
успешных usage calls, prompt 275695, candidates 177993, thoughts 90709, оценка
$0.47198. Итог — $0.90463. Один HTTP 502 на `/api/parse` восстановлен client
retry, импорт завершился за ~5 минут.

Live-счётчики по 12 типам (канонический порядок): 12,18,11,11,14,12,11,9,15,12,
10,8 = 143; curated: 12,16,13,12,14,12,12,9,13,12,9,8 = 142 — расхождение не
объяснено в этой сессии. Все 12 first variants открылись в content state,
force-stop/cold launch сохранил оба курса. Временные PDF удалены с телефона,
импортированные курсы оставлены.

Vercel sensitive env недоступны из CLI в этой сессии, поэтому live JSON для
answer-key/verbatim audit безопасно не выгружен; debug/admin backdoor не
добавлялся.

Следующему агенту: structural Premium E2E — PASS, но semantic correctness —
NOT CLOSED. Count drift (143 live vs 142 curated) — release risk. Приоритетная
задача — получить live JSON безопасным способом (без добавления backdoor) и
прогнать DTO/answer-key/verbatim/diff audits именно для 208-страничной версии,
прежде чем считать Premium full-PDF gate полностью верифицированным.

### Premium semantic audit выполнен — 19 июля 2026

Live JSON уже безопасно извлечён через кратковременную same-package/same-cert
diagnostic build; повторять extraction не нужно. Канонический production APK
восстановлен, не debuggable, оба курса сохранены. Временный worktree/APK/signing
copies удалены. Private audit artifacts:
`/home/igor/Downloads/exam-trainer-audit-live/`.

Оба курса прошли Flutter `ParsedCourse` и DTO всех 12 типов. Однако live cold
parse семантически не прошёл gate: 21/143 byte-identical с curated v37, 122
new/changed; 85 общих identities имеют payload changes, 28 live-only против 27
curated-only. PDF-highlight audit подтвердил три реальные ошибки answer key:
`beschwerde` v5 Q19, `sprachbausteine_teil2` v1 Q55, `hoeren_teil3` v5 Q34.
Один AMBIGUOUS — false positive двух редакций. Все 24 verbatim candidates после
ручной/независимой сверки — false positives/intentional representation; курс по
ним не менять.

Сохранять production curated v37 и Redis cache без изменений. Не публиковать и
не auto-merge `premium-full-live-miss.json`. Следующая самостоятельная задача:
root-cause identity/version drift и три answer-key ошибки, затем минимально
усилить prompts/schema/post-parse gate, доказать изменения offline replay и
только после этого разрешать ограниченный paid reparse. Не делать новый полный
$0.90 production run до локального regression gate; не добавлять debug/admin
endpoint для выгрузки курсов.

### Текущий handoff: v38 semantic remediation

Backend/Flutter подготовлены локально, production ещё не изменён. Wrong keys:
Beschwerde v5 Q19, Sprachbausteine Teil 2 v1 Q55, Hören Teil 3 v5 Q34. Repair
использует physical `PDF_CORRECT` только при уникальном option text; Teil 2
inline fallback требует exact и единогласный `N (letter - text)` по chunks.

Только v38-клиент отправляет `X-Exam-Trainer-Answer-Markers: v38` на convert и
parse. Backend без заголовка обязан оставаться legacy-v37. Порядок: deploy
dual-format backend; проверить legacy digest; вычислить новый digest; dry-run/
apply/read-back trusted 142-item doc-cache в `v30.v38`; затем build/install v38
APK. v37 Redis сохранить. Live 143 JSON не публиковать и не auto-merge; paid
full parse не запускать.

Offline gate: `scripts/offline_semantic_gate.py`; реальный fixture ожидаемо FAIL
(21 exact, 8 metadata-only, 86 payload, 28 fresh-only, 27 trusted-only).
`inject_curated.py` требует явных source/target marker formats и cache versions. Перед
коммитом выполнить полный Flutter/backend gate, общий diff и Hermes Memory.

Последний verified gate: Flutter 352/352, coverage 55.25%, backend 217 tests +
54 subtests, Android integration 2/2 на SM-S938B. Clean APK hash:
`11e684a949942f9747e48314f6b793d263b8177eb9e1a7eebb6cfd73f00c7153`.
Не устанавливать его: curated v38 key ещё отсутствует, versionCode всё ещё 10.

Dual-format backend `ad87d22` уже production (`dpl_Da6iCoFcXQResqAM7tPoDdmdEvbE`,
READY); safe 401/OPTIONS+CORS smoke пройден. Flutter `d725b51` запушен, но APK
не установлен. Следующий разрешённый rollout-шаг — только публикация trusted
142-item v38 Redis doc-key с read-back; после неё versionCode bump и новый APK.

### Актуальный handoff: v38 cache и build 11 готовы — 20 июля 2026

Предыдущий handoff выше завершён до device-smoke стадии. Production Redis v38
опубликован переносом проверенного v37 value без Gemini parse. Source и target
байт-в-байт равны (SHA-256
`adf1cbca8b386eea6d62215fc6df0c158b6928060e800ea952f887768e4c8870`), оба
валидны как 12 sections/142 items; v37 не изменён. Временные Upstash credentials
уничтожены, повторно запрашивать или сохранять их не нужно.

Flutter теперь `1.0.0+11`. Production APK/AAB лежат в Downloads под именами
`exam-trainer-v38-1.0.0+11-production-release.*`; SHA-256 APK начинается
`f555f862`, AAB — `afd031af`. Package/API/upload certificate проверены. APK уже
обновил SM-G985F по Wi-Fi с versionCode 10 до 11 без очистки данных.

Остался только rollout gate: разблокировать устройства, по возможности
подключить SM-S938B по USB, выполнить `tool/run_android_integration.sh <id>` и
проверить на Premium исходный 207-page PDF как быстрый v38 cache HIT с полным
курсом 12/142; на Free проверить обычный импорт/ограничение без paid parse.
Wireless integration на SM-G985F дважды оборвался на служебном WebSocket до
старта test body; это не считать PASS и не повторять бесконечно. Не очищать
данные, не удалять production package, не запускать новый paid full parse и не
загружать AAB в Play до зелёного device-smoke.

Позднее wireless-debug порт обновлён и SM-G985F успешно прошёл оба integration
теста (PDF 1/1, accessibility 1/1). Production package versionCode 11 и два
курса сохранены, integration package удалён. Free smoke PASS: Home после cold
launch, профиль `Kostenloses Konto`, cached course открывается и показывает по
одной вариации на раздел. Не повторять Free/integration gate без нового дефекта.
Единственный незакрытый rollout-шаг — Premium cache-hit исходного 207-page PDF
на USB SM-S938B, затем обновить docs/Hermes и разрешить AAB к загрузке.

Этот последний шаг завершён. SM-S938B обновлён до production versionCode 11 с
сохранением Premium account и двух курсов. Exact 207-page PDF (SHA-256
`53634b0c...`) импортирован за ~26 секунд; новый курс содержит 142 items и виден
на Home. Vercel production log подтвердил точный v38 doc-cache key,
`CACHE_LOOKUP hit=True`, HTTP 200, поэтому paid parse не выполнялся. Временный
PDF удалён с телефона. Rollout v38 полностью закрыт; не повторять device/import
smoke без нового дефекта. Следующие работы брать только из актуальных P1/P2 или
Play Console checklist, не из завершённых handoff-разделов выше.
