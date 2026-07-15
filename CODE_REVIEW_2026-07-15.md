# Code review: Exam Trainer

> **Исторический snapshot исходного ревью.** Числа, формулировки проблем и
> выводы ниже сохранены в первоначальном виде. Актуальное состояние после
> исправлений находится в разделе [«Статус реализации»](#статус-реализации),
> а продолжение работы — в [`NEXT_AGENT_PROMPT.md`](NEXT_AGENT_PROMPT.md).

Дата: 15 июля 2026
Область проверки: Flutter-клиент `exam_trainer` (Android в приоритете)
Версия: `1.0.0+10`

## Краткий вывод

Приложение находится в рабочем состоянии: статический анализ проходит без ошибок, все 107 автоматических тестов проходят, установленная сборка по умолчанию обращается к production API, Firebase ID token используется вместо общего секрета, а локальные данные разделены по UID пользователя.

Однако утверждать, что приложение уже не содержит значимых багов и полностью готово к массовой публикации, пока нельзя. Главные риски сосредоточены в основном пользовательском сценарии — импорте PDF — и в локальном хранении курсов. Большой PDF может вызвать нехватку памяти; уход с экрана во время импорта способен привести к `setState() called after dispose`; один повреждённый JSON-файл может сделать все локальные курсы невидимыми; ошибки загрузки упражнений часто маскируются бесконечным индикатором. Облачная синхронизация является best-effort и не гарантирует повтор неудачной загрузки или удаления.

Рекомендуемый статус: **закрытая/внутренняя beta после исправления P0**, затем ручной прогон на нескольких реальных Android-устройствах. Для публичного Play Market релиза сначала следует закрыть пункты CR-01—CR-06.

## Что проверено

- структура проекта, зависимости и границы слоёв;
- запуск приложения, Firebase initialization, auth redirect и device gate;
- Google/email authentication и работа с Firebase ID token;
- выбор, конвертация, кэширование и AI-парсинг PDF;
- локальное хранение, облачная синхронизация, удаление курсов и избранное;
- загрузка и отображение упражнений, TTS/audio cache;
- Android manifest и release-конфигурация;
- локализация, доступность и обработка ошибок;
- существующие unit/widget-тесты и фактическое покрытие;
- `flutter analyze`, `flutter test --coverage`, `flutter pub outdated`.

Backend и его инфраструктура в эту проверку не входили. Поэтому серверная проверка Firebase token, правила доступа к курсам, лимиты размера запросов, rate limiting, защита API-кэша и хранение PDF/распознанного текста должны быть предметом отдельного backend/security review.

## Результаты автоматической проверки

| Проверка | Результат |
|---|---|
| `flutter analyze` | успешно, `No issues found` |
| `flutter test --coverage` | успешно, 107/107 тестов |
| Покрытие загруженных в тестах строк | 749/2481, 30,19% |
| Устаревшие пакеты | 23 пакета имеют более новые несовместимые версии |
| Прямые зависимости с доступным major upgrade | `device_info_plus`, `file_picker`, `go_router`, `google_fonts` и др. |

Показатель 30,19% относится только к исходникам, попавшим в LCOV во время тестов. Несколько экранов вообще не были загружены тестами, поэтому число нельзя считать полным покрытием всего `lib/`; оно скорее завышает реальную долю проверенного приложения.

## Сильные стороны

1. **Нет общего backend-секрета в APK.** Запросы получают Firebase ID token через [`auth_service.dart`](lib/services/auth_service.dart#L63), а production endpoint задан по умолчанию в [`api_config.dart`](lib/services/api_config.dart#L1).
2. **Изоляция пользовательских данных.** Курсы и избранное namespaced по Firebase UID; это предотвращает показ Premium-данных другому аккаунту на том же устройстве. Есть отдельные тесты UID-изоляции.
3. **Разумная защита парсинга.** В `ParseService` есть versioned cache keys, timeouts, retry/validation и тесты реальных пограничных случаев распознавания.
4. **Запуск больше не удерживает чёрный platform surface.** Первый Flutter frame рисуется до завершения Firebase startup, а overlay остаётся до готовности страницы.
5. **Сетевые операции имеют тайм-ауты.** Это лучше бесконечного ожидания и присутствует в импорте, TTS, синхронизации и device gate.
6. **Home уже движется к тестируемой архитектуре.** `HomeViewModel` получает зависимости через функции и имеет защиту от устаревших результатов параллельных refresh.
7. **Release оптимизирован.** Включены minification и resource shrinking.

## Сводка замечаний

| ID | Приоритет | Область | Риск |
|---|---|---|---|
| CR-01 | P0 / высокий | Локальное хранение | Повреждение одного файла скрывает все курсы |
| CR-02 | P0 / высокий | Импорт PDF | Нехватка памяти на больших PDF |
| CR-03 | P0 / высокий | Импорт PDF | Асинхронная работа переживает экран и вызывает ошибки состояния |
| CR-04 | P0 / высокий | Упражнения | Ошибка загрузки выглядит как вечный spinner |
| CR-05 | P0 / высокий | Release | Release незаметно подписывается debug-ключом |
| CR-06 | P0 / высокий | Тесты | Нет сквозного теста главного сценария PDF → курс → упражнение |
| CR-07 | P1 / средний | Cloud sync | Потеря загрузки/удаления при временном сбое |
| CR-08 | P1 / средний | Модели данных | `dynamic`/casts превращают schema drift в runtime crash |
| CR-09 | P1 / средний | Startup | Сетевой device gate задерживает холодный старт до 15 секунд |
| CR-10 | P1 / средний | Device limit | Fail-open позволяет обходить лимит при ошибке сервера |
| CR-11 | P1 / средний | Ошибки/API | Пользователю показывается сырое тело серверной ошибки |
| CR-12 | P1 / средний | Android privacy | Запрошены неиспользуемые media/storage permissions |
| CR-13 | P2 / средний | Архитектура | UI напрямую управляет сервисами и динамическими DTO |
| CR-14 | P2 / низкий | TTS | Дисковый audio cache не ограничен |
| CR-15 | P2 / средний | i18n/a11y | Частичная локализация и слабое semantic-покрытие |
| CR-16 | P2 / низкий | Dependencies | Накопилось несколько major upgrades |

## Подробные замечания и рекомендации

### CR-01 — Неатомарное хранение и отказ всей библиотеки из-за одного файла

**Приоритет:** P0, высокий.
**Код:** [`course_storage.dart`](lib/services/course_storage.dart#L61), [`course_storage.dart`](lib/services/course_storage.dart#L121), [`home_view_model.dart`](lib/ui/features/home/view_models/home_view_model.dart#L77).

Курс записывается прямо в конечный `<id>.json`. При остановке процесса, нехватке места или сбое записи файл может остаться частичным. `_loadLocal()` декодирует все файлы без индивидуальной обработки ошибок; исключение одного курса прекращает загрузку всей библиотеки. `HomeViewModel` затем преобразует исключение в пустой список, и пользователь видит, будто исчезли все курсы.

**Рекомендация:**

- писать `<id>.json.tmp`, делать `flush`, затем атомарно переименовывать;
- ловить ошибку отдельно для каждого файла, помещать повреждённый файл в quarantine и продолжать загрузку остальных;
- не заменять уже показанные данные пустым списком при refresh-ошибке;
- хранить явный `schemaVersion` и миграции;
- добавить пользователю действие «Повторить» и диагностическое сообщение;
- добавить тесты: оборванный JSON, отсутствующий файл из prefs, неизвестная версия схемы, нехватка места.

**Критерий готовности:** один повреждённый курс не влияет на остальные и не уничтожает предыдущую валидную копию.

### CR-02 — PDF полностью и дважды удерживается в памяти

**Приоритет:** P0, высокий.
**Код:** [`import_screen.dart`](lib/screens/import_screen.dart#L52), [`import_screen.dart`](lib/screens/import_screen.dart#L97), [`parse_service.dart`](lib/services/parse_service.dart#L108).

`FilePicker` вызывается с `withData: true`, поэтому весь PDF загружается в RAM. Затем `Uint8List.fromList(bytes)` создаёт ещё одну копию, после чего `http.post(body: pdfBytes)` также должен подготовить тело запроса. На устройствах с небольшой памятью крупный или специально подобранный PDF способен завершить процесс по OOM.

**Рекомендация:**

- получать путь/stream вместо `withData: true` и загружать через streamed request;
- до импорта проверять размер и вводить согласованный с backend предел, например 25–50 MB;
- проверять PDF magic bytes `%PDF-`, а не только расширение;
- если streaming endpoint пока невозможен, как минимум убрать вторую копию и отказать до чтения слишком большого файла;
- протестировать 1 MB, граничный размер, файл выше лимита и malformed PDF на реальном устройстве.

### CR-03 — Импорт не привязан к lifecycle и не поддерживает отмену/восстановление

**Приоритет:** P0, высокий.
**Код:** [`import_screen.dart`](lib/screens/import_screen.dart#L97), [`import_screen.dart`](lib/screens/import_screen.dart#L113), [`import_screen.dart`](lib/screens/import_screen.dart#L179), [`import_screen.dart`](lib/screens/import_screen.dart#L242).

После нескольких `await` вызывается `setState` без проверки `mounted`. AppBar позволяет уйти назад во время операции. В результате фоновый импорт продолжится, может сохранить курс после ухода пользователя и попытаться изменить уничтоженный State. Длинная AI-обработка не отменяется и не восстанавливается после остановки приложения.

**Рекомендация:** вынести импорт в `ImportController` с явными состояниями `idle/selecting/uploading/converting/discovering/parsing/saving/success/error/cancelled`; использовать отменяемый HTTP client; во время критической операции показывать подтверждение выхода через `PopScope`; перед каждым UI update проверять актуальность operation ID и `mounted`. Для длительной серверной обработки предпочтителен job API (`POST /imports`, polling/status), чтобы восстановить прогресс после перезапуска.

### CR-04 — Ошибки загрузки упражнений превращаются в бесконечный spinner

**Приоритет:** P0, высокий пользовательский эффект.
**Код:** [`universal_exercise_screen.dart`](lib/screens/universal_exercise_screen.dart#L57), [`universal_exercise_screen.dart`](lib/screens/universal_exercise_screen.dart#L130), [`sprachbausteine_exercise_screen.dart`](lib/screens/sprachbausteine_exercise_screen.dart#L59), [`beschwerde_exercise_screen.dart`](lib/screens/beschwerde_exercise_screen.dart#L60).

Несколько экранов подавляют исключение через `catch (_) {}`. Если курс не найден, индекс неверен, локальный JSON повреждён или схема изменилась, `_variant` остаётся `null`, а UI навсегда показывает `CircularProgressIndicator`. Аналогичное поведение есть в специализированных exercise screens.

**Рекомендация:** использовать единый `AsyncState<T>` и различать loading/loaded/notFound/corrupt/offline/error; показывать понятное сообщение, Retry и возврат к списку. Проверять `index >= 0 && index < length`. Добавить widget-тест каждому типу экрана на success, missing course, invalid index и storage exception.

### CR-05 — Release-сборка автоматически использует debug signing

**Приоритет:** P0 перед публикацией.
**Код:** [`build.gradle.kts`](android/app/build.gradle.kts#L11), [`build.gradle.kts`](android/app/build.gradle.kts#L56).

При отсутствии `key.properties` release APK успешно собирается с debug-ключом. Это удобно локально, но опасно для релизного процесса: артефакт выглядит как release, хотя Play Console не примет его как обновление правильного приложения, а ручная раздача создаст несовместимую цепочку подписей.

**Рекомендация:** release-задача должна fail closed с понятной ошибкой при отсутствии upload keystore. Для локальной производительной сборки завести отдельный build type/flavor, например `benchmark` или `internal`. В CI добавить проверку сертификата через `apksigner verify --print-certs` и сравнение ожидаемого SHA-256.

### CR-06 — Главный бизнес-сценарий не проверяется сквозным тестом

**Приоритет:** P0 по качеству.
**Код:** каталог [`test`](test), [`widget_test.dart`](test/widget_test.dart#L1).

107 тестов — хороший результат, но большая часть относится к валидации `ParseService`. Нет `integration_test`, который проверяет вход, выбор PDF, cache hit/miss, создание курса, открытие каждого упражнения, перезапуск и повторную загрузку. `ImportScreen` имеет только тест преобразования free-tier cache и лишь 7,19% instrumented line coverage; `UniversalExerciseScreen` — 3,18%; audio player — 0%. Placeholder test не несёт продуктовой ценности.

**Рекомендация:** внедрить подменяемые интерфейсы `AuthRepository`, `ImportRepository`, `CourseRepository`, fake HTTP/backend и постоянные integration/widget tests. Минимальный smoke journey: авторизованный пользователь → fixture PDF/cache → успешный импорт → курс виден после restart → упражнение отвечает и считает результат → удаление не воскрешает курс.

### CR-07 — Облачная синхронизация не гарантирует доставку изменений

**Приоритет:** P1, средний.
**Код:** [`course_storage.dart`](lib/services/course_storage.dart#L80), [`course_storage.dart`](lib/services/course_storage.dart#L136), [`course_storage.dart`](lib/services/course_storage.dart#L175).

Upload/delete запускаются fire-and-forget. После ошибки нет постоянной очереди, backoff или видимого статуса. `_pendingDeletes` существует только в памяти: после перезапуска неуспешно удалённый в облаке курс может снова загрузиться. Merge только добавляет отсутствующие ID и не разрешает обновления/конфликты существующего курса. HTTP status upload/delete также не проверяется как успешный.

**Рекомендация:** локальная outbox-таблица с операциями upsert/delete, persistent tombstones, exponential backoff и idempotency keys. Сервер и клиент должны иметь `updatedAt`/revision и явную стратегию конфликта. В UI показывать `localOnly/syncing/synced/syncError`, а не выдавать best-effort за гарантированную синхронизацию.

### CR-08 — Динамическая схема проходит через всё приложение

**Приоритет:** P1, средний.
**Код:** [`parsed_course.dart`](lib/models/parsed_course.dart#L80), [`universal_exercise_screen.dart`](lib/screens/universal_exercise_screen.dart#L42), [`app.dart`](lib/app.dart#L205).

`sections` имеет тип `Map<String, List<dynamic>>`, после чего экраны выполняют многочисленные `as Map<String, dynamic>`, `cast<...>()` и прямые обращения к полям. Кэш, backend и UI фактически связаны некомпилируемым контрактом. Любой schema drift приводит к runtime exception. `int.parse` route index также падает на некорректной deep link.

**Рекомендация:** типизированные immutable DTO для каждого вида упражнения, defensive `fromJson`, sealed union для section type, `schemaVersion`, миграции и contract tests на реальные fixtures. Маршрут должен использовать `int.tryParse` и отдавать not-found/error page.

### CR-09 — Device gate находится на критическом пути холодного запуска

**Приоритет:** P1, средний.
**Код:** [`main.dart`](lib/main.dart#L25), [`app.dart`](lib/app.dart#L74), [`device_service.dart`](lib/services/device_service.dart#L20).

Для уже авторизованного пользователя `prepareAppStartup()` ждёт `/api/device` до 15 секунд до создания основного приложения. Брендированный preloader скрывает чёрный экран, но не уменьшает реальную задержку. Кроме того, минимальная демонстрация splash принудительно длится 1,2 секунды даже на быстром устройстве.

**Рекомендация:** измерить cold/warm startup через Firebase Performance или собственные метрики; не удерживать Home на сетевом запросе, если есть свежий подписанный/локальный allow-state; выполнять revalidation в фоне и переводить на limit screen при достоверном ответе. Принудительный минимум оставить только если он подтверждён UX-тестом, иначе уменьшить/убрать.

### CR-10 — Device limit fail-open при любом неожиданном ответе

**Приоритет:** P1, средний бизнес-риск.
**Код:** [`device_service.dart`](lib/services/device_service.dart#L41), [`device_service.dart`](lib/services/device_service.dart#L62).

Любой non-200, malformed JSON, timeout или auth error трактуется как `allowed`. Следовательно, контроль, который комментарий называет «единственной реальной проверкой», отключается при сбое endpoint. `forceRegisterCurrentDevice()` не проверяет status и подавляет все ошибки, поэтому UI может считать операцию успешной, когда сервер ничего не изменил. UUID хранится в SharedPreferences и после переустановки меняется: это ID установки, а не стабильного устройства.

**Рекомендация:** определить продуктовую политику явно. Для платного доступа разумен short-lived cached allow с grace period; 401/403 и валидный `limitReached` не должны fail-open; 5xx/offline могут использовать последний подтверждённый результат. `force` обязан вернуть typed result. На backend необходимы аудит, rate limit и защита от бесконечной генерации installation IDs.

### CR-11 — Сырые backend-ошибки попадают в UI

**Приоритет:** P1, средний.
**Код:** [`parse_service.dart`](lib/services/parse_service.dart#L108), [`parse_service.dart`](lib/services/parse_service.dart#L194), [`import_screen.dart`](lib/screens/import_screen.dart#L67).

`ParseService` включает полное `res.body` в `Exception`, а `ImportScreen` показывает `e.toString()` пользователю. Это даёт технические англо-/русскоязычные сообщения, раскрывает детали API и может создать очень большой error widget. При частичных ошибках сырые ответы также сохраняются для диалога.

**Рекомендация:** typed `ApiException(code, status, retryable, correlationId)`; локализованное отображение по code; безопасное ограничение длины; исходная диагностическая информация — только в crash/telemetry системе с редактированием данных. Для 401, 403 Premium, 413, timeout и 5xx нужны отдельные действия.

### CR-12 — Android запрашивает лишние разрешения

**Приоритет:** P1, средний privacy/review-риск.
**Код:** [`AndroidManifest.xml`](android/app/src/main/AndroidManifest.xml#L1).

Для выбора PDF через системный Storage Access Framework приложению обычно не нужны `READ_EXTERNAL_STORAGE` и тем более `READ_MEDIA_IMAGES`. Они не соответствуют заявленной функции и увеличивают поверхность privacy review. Label приложения остаётся техническим `exam_trainer`. Явная backup/data-extraction policy также отсутствует, хотя локально сохраняется полный распознанный учебный материал.

**Рекомендация:** удалить неиспользуемые permissions после проверки на минимальной поддерживаемой Android-версии; задать пользовательское имя; принять явное решение по Android backup (`allowBackup`/`dataExtractionRules`) с учётом курсов, UID namespace и удаления аккаунта.

### CR-13 — Архитектурная миграция выполнена только для Home

**Приоритет:** P2, средний долгосрочный.
**Код:** [`home_view_model.dart`](lib/ui/features/home/view_models/home_view_model.dart#L14), [`import_screen.dart`](lib/screens/import_screen.dart#L39), [`app.dart`](lib/app.dart#L37).

Home имеет выделенный ViewModel, но остальные экраны напрямую вызывают глобальные singleton services, парсят dynamic JSON и управляют сетевым workflow. `ImportScreen` одновременно является view, orchestration layer и бизнес-правилами Premium/free. Глобальный router и глобальное состояние device gate затрудняют изоляцию тестов. Крупные файлы (`home_screen.dart` около 1123 строк, `universal_exercise_screen.dart` около 1086, `parse_service.dart` около 939) увеличивают связанность.

**Рекомендация:** постепенно перейти к слоям UI → application/controller → repositories → data sources. Не требуется переписывать всё сразу: начать с Import, затем Course/Exercise loading. Интерфейсы репозиториев и constructor injection дадут наибольший выигрыш для тестов.

### CR-14 — TTS cache растёт без ограничений

**Приоритет:** P2, низкий/средний.
**Код:** [`tts_service.dart`](lib/services/tts_service.dart#L27), [`tts_service.dart`](lib/services/tts_service.dart#L179).

Каждая уникальная реплика сохраняется в `Documents/tts_cache`, но нет общего размера, TTL, LRU или действия «Очистить аудио». При множестве импортированных курсов каталог будет расти постоянно. Запись mp3 также производится сразу в конечный файл.

**Рекомендация:** перенести воспроизводимый cache в cache directory, ввести лимит/TTL/LRU и атомарную запись; добавить размер и очистку в настройках. Пользовательские данные, которые нельзя восстановить, должны оставаться отдельно.

### CR-15 — Локализация и accessibility неполные

**Приоритет:** P2, средний для международного релиза.
**Код:** [`startup_screen.dart`](lib/ui/features/startup/startup_screen.dart#L103), [`dialogue_audio_player.dart`](lib/widgets/dialogue_audio_player.dart#L250), [`telefonnotiz_exercise_screen.dart`](lib/screens/telefonnotiz_exercise_screen.dart#L60).

Поддерживаются четыре locale, но в экранах упражнений и speaking bank остаётся много жёстко заданного немецкого текста. Явные `Semantics` найдены в основном на startup и Home; для audio controls, progress/result feedback и интерактивных карточек нет системного semantic-подхода. `TapGestureRecognizer` внутри consent-текста требует отдельной проверки TalkBack и управления жизненным циклом recognizer.

**Рекомендация:** вынести весь UI-текст в ARB/generated l10n; добавить semantic labels/hints/selected/value для аудио, вариантов ответа и прогресса; обеспечить touch targets минимум 48 dp; прогнать TalkBack, font scale 200%, high contrast и keyboard navigation. Добавить semantic widget tests на критические экраны.

### CR-16 — Зависимости требуют планового обновления

**Приоритет:** P2, низкий сейчас.

`flutter pub outdated` показывает 23 пакета с более новыми несовместимыми версиями; пять ограничений блокируют доступную resolvable major-версию. Особенно заметны `go_router 13 → 17`, `device_info_plus 10 → 12/13`, `google_fonts 6 → 8`, `file_picker 10 → 11`.

**Рекомендация:** обновлять по одному семейству в отдельной ветке после появления integration smoke tests. Сначала patch/minor Firebase, затем file/device plugins, затем router. Не объединять major dependency migration с функциональным релизом.

## Архитектурная оценка

Текущее устройство можно кратко представить так:

```text
Screens / Widgets
  ├─ напрямую вызывают singleton Services
  ├─ напрямую читают Map<String, dynamic>
  └─ сами управляют loading/error/navigation
          │
          ▼
Auth / Parse / CourseStorage / TTS / Device services
          │
          ├─ Firebase
          ├─ REST API
          ├─ SharedPreferences
          └─ JSON files
```

Целевая эволюция без полной переписи:

```text
UI (render + user events)
          ▼
ViewModel / Controller (typed state + use cases)
          ▼
Repository interfaces (Course, Import, Auth, Audio)
          ▼
Remote and local data sources + typed DTO/mappers
```

Home уже демонстрирует подходящую точку начала. Следующим кандидатом должен быть Import, потому что именно там сосредоточены длительные операции, Premium-правила, retry/cancel и основной денежный сценарий.

## Рекомендуемый план работ

### Этап 1 — Перед следующей beta (P0)

1. Сделать атомарную запись курсов и изоляцию повреждённых файлов.
2. Ограничить размер PDF, убрать вторую копию и проверить сигнатуру файла.
3. Сделать ImportController, безопасный lifecycle, отмену/подтверждение выхода и явные ошибки.
4. Заменить вечные spinner на loading/error/not-found states.
5. Запретить debug signing для release.
6. Добавить integration smoke flow главного сценария.

Оценка: примерно 6–10 рабочих дней с тестами, без изменения backend на job-based import. Streaming/job API потребует отдельной backend-работы.

### Этап 2 — Перед публичным Play Market релизом (P1)

1. Persistent outbox/tombstones и видимый статус cloud sync.
2. Типизированные модели импортированных упражнений и schema version.
3. Typed API errors и локализованное отображение.
4. Пересмотреть device gate policy и убрать его задержку с критического startup path.
5. Удалить лишние Android permissions и определить backup policy.
6. Провести отдельный backend security review.

Оценка: 2–4 недели, главным образом зависит от изменений server API и миграции существующих курсов.

### Этап 3 — После стабилизации (P2)

1. Продолжить выделение ViewModel/repositories.
2. Ограничить TTS cache.
3. Завершить локализацию и TalkBack audit.
4. Поэтапно обновить major dependencies.
5. Добавить performance telemetry: cold start, import duration, cache hit rate, parse failures, OOM/crash-free users.

## Минимальная матрица ручного тестирования

| Сценарий | Варианты |
|---|---|
| Устройства | low-RAM Android, среднее устройство, современный flagship/tablet |
| Android | минимальная поддерживаемая, Android 13, 14/15/актуальная target версия |
| Сеть | Wi-Fi, LTE, offline, timeout, переключение сети во время импорта |
| PDF | маленький, большой у лимита, выше лимита, password-protected, malformed, scan-only, повторный cache hit |
| Аккаунты | email, Google, sign-out/in другим UID, удаление аккаунта, превышение device limit |
| Жизненный цикл | back во время импорта, background/foreground, process kill, rotation, повторный запуск |
| Хранение | повреждённый JSON, отсутствующий файл, мало места, неуспешный cloud upload/delete |
| UI | font scale 200%, TalkBack, длинные переводы, маленький экран, landscape |

## Definition of Done для релиз-кандидата

- `flutter analyze` и все unit/widget/integration tests проходят в CI;
- release build прекращается без правильного upload keystore;
- основной PDF journey проверен автоматически и вручную минимум на трёх классах устройств;
- большой файл не вызывает OOM и имеет понятный предел;
- уход с экрана/kill процесса не приводит к скрытому сохранению или `setState after dispose`;
- повреждение одного курса не скрывает остальные;
- любой экран заканчивает загрузку состоянием content/error/not-found, а не вечным spinner;
- cloud sync имеет наблюдаемый результат и повторяет неудачные операции;
- Android permissions соответствуют реально используемым функциям;
- backend auth/rules/rate limits подтверждены отдельным security review;
- crash reporting и ключевые performance/import metrics включены с privacy-safe redaction.

## Итоговая оценка

Кодовая база имеет хорошую функциональную основу и заметный объём тестов вокруг наиболее сложной логики парсинга. Проблема не в том, что приложение «не работает», а в том, что несколько редких сбоев сейчас превращаются в потерю видимости данных, бесконечную загрузку или незавершённую синхронизацию без понятного восстановления. После закрытия P0 приложение будет пригодно для расширенной beta; после P1, backend security review и матрицы реальных устройств — для уверенного публичного релиза.

## Статус реализации

Обновлено 15 июля 2026 года после проверки замечаний по текущему коду. Все
CR-01—CR-06 были подтверждены и исправлены без изменения backend API,
production endpoint, Firebase Auth, UID-изоляции, Free/Premium-ограничений,
версий кэша или формата `ParsedCourse`.

| ID | Статус | Реализация и проверка |
|---|---|---|
| CR-01 | Закрыт | Локальная запись выполняется через flushed `.tmp` и atomic rename. Ошибки разбираются отдельно для каждого файла; повреждённые байты сохраняются в последовательных `.corrupt` quarantine-копиях, отсутствующие файлы удаляются только из индекса prefs, валидные курсы продолжают загружаться. Home сохраняет уже показанный список при refresh-ошибке. |
| CR-02 | Закрыт с документированным server-side ограничением | Picker использует path и `withData: false`; до upload проверяются лимит 25 MiB и `%PDF-`. Клиент отправляет файл через `http.StreamedRequest` с известным `Content-Length`, без полной `Uint8List` и второй копии. Backend по-прежнему принимает прежнее бинарное тело `/api/convert`; его внутренняя обработка не стала job/stream API. |
| CR-03 | Закрыт в рамках совместимого client-side решения | Добавлены `PdfImportController`, явные phases и operation id. Каждый async boundary, progress callback, save, dialog и navigation проверяет актуальность операции и lifecycle; dispose/повторный запуск инвалидируют старый результат. Отмена кооперативная: после ухода нет поздних UI update/save/navigation, но уже начатую серверную работу без job/cancel API нельзя гарантированно остановить на сервере. Raw exceptions в UI не показываются. |
| CR-04 | Закрыт | Course, section list и шесть exercise screens различают loading/not-found/error, проверяют отрицательный и выходящий за границы index, показывают безопасное сообщение, Retry и Back. Storage/schema exceptions больше не оставляют spinner. |
| CR-05 | Закрыт | Release build больше не выбирает debug signing. Проверяются наличие `android/key.properties`, четыре обязательных поля и keystore; release task fail-closed с понятной `GradleException`. Изолированная сборка без signing-файлов действительно остановилась, а рабочая release APK собралась и подписана сертификатом `CN=Exam Trainer`. |
| CR-06 | Закрыт | Добавлен стабильный fixture и smoke journey с fake UID-isolated repository: cached PDF result → disk save → Home → Course → Section → Exercise → результат 1/1 → новый repository instance → повторная загрузка Home. Production backend не вызывается. Device entry point использует `IntegrationTestWidgetsFlutterBinding`; тот же flow входит в обычный host test suite. |

Добавлены проверки повреждённого JSON, прерванной записи, отсутствующего
prefs-файла, сохранения Home при refresh error, PDF size/magic, dispose и stale
import operation, всех exercise storage errors, missing/invalid indexes, Retry,
release signing и основного smoke flow. После реализации проходят 132 теста,
`flutter test --coverage` даёт 1555/4115 загруженных строк (37,79%).

Финальные локальные gates: `dart format --output=none
--set-exit-if-changed .`, `flutter analyze`, `flutter test`, `flutter test
--coverage`, production release APK build в
`build/app/outputs/flutter-apk/app-production-release.apk`, `apksigner verify`
и `git diff --check` прошли.
Прямой device integration smoke прошёл 1/1 на физическом Samsung SM-S938B;
идентичный host-запуск также прошёл. Linux desktop runner отдельно остаётся
непригоден из-за несовместимости snap Flutter linker с host GLIBC/GStreamer,
но это больше не блокирует device-проверку.

После первой device-проверки выявлен отдельный риск Flutter runner: его
стандартный teardown может удалить установленный production package даже при
сборке flavored APK. Для regression-тестов добавлены `production` (flavor по
умолчанию, прежний applicationId) и изолированный `integration` с
applicationId `com.linguaproapps.exam_trainer.integration`. Поддерживаемый
запуск на физическом Android выполняется только командой
`tool/run_android_integration.sh <device-id>`: скрипт использует
`--flavor integration --no-uninstall`, удаляет строго integration package и
проверяет, что ранее установленный production package не исчез. Прямой
`flutter test -d <device> integration_test/...` на телефоне с production
приложением использовать нельзя. Повторный защищённый прогон прошёл 1/1, после
него на Samsung осталась production-версия `1.0.0+10`, integration package
удалён.

### P1 (CR-07—CR-12) — обновлено 15 июля 2026

Все шесть замечаний P1 подтверждены по текущему коду. CR-07 и CR-09—CR-12
закрыты; CR-08 закрыт только на наиболее опасных входных границах и поэтому
честно отмечен как частичный. Production endpoint, Firebase Auth,
UID-изоляция, Free/Premium-ограничения и версии кэша сохранены. Backend API
изменён минимально только в семантике подтверждения: существующая форма
`{ok:true/false}` сохранена, но storage failure теперь даёт 503 вместо
ложного 200.

| ID | Статус | Реализация и проверка |
|---|---|---|
| CR-07 | Закрыт | `CourseStorage` получил персистентный per-UID outbox (`course_sync_outbox_<uid>` в SharedPreferences) для upsert/delete вместо fire-and-forget. Ретраи идут с экспоненциальным backoff (5с → 30 мин), опортунистически из `save`/`delete`/`loadAll`, с дедупликацией параллельных прогонов и UID, зафиксированным на момент запуска (не «плывёт» при смене аккаунта во время фонового прогона). `saved:false` в теле 200-ответа теперь трактуется как неуспех (раньше проверялся только statusCode). Пропавшие удаления переживают перезапуск процесса (раньше `_pendingDeletes` было только в памяти). Добавлен видимый `CourseSyncState` (`synced/pending/syncing/error`) с маленьким индикатором на карточке курса. Revisions/конфликты между устройствами по-прежнему только additive-merge — full conflict resolution требует backend-контракта (revision/updatedAt в ответе) и явно оставлено как задокументированный остаточный риск, а не изменено без согласования. 8 новых тестов (`course_storage_sync_outbox_test.dart`). |
| CR-08 | Частично закрыт: главные input-границы | Route `:index` использует `int.tryParse` + существующий `CourseLoadFailureView(notFound)` вместо краша при невалидном deep-link. `UniversalExerciseScreen`, `BeschwerdeExerciseScreen`, `HoerenTeil1ExerciseScreen`, `TelefonnotizExerciseScreen`, `SprachbausteineExerciseScreen` и `SectionListScreen` теперь форсируют вложенные `List.cast<Map<String,dynamic>>().toList()`-касты внутри уже существующего `try/catch` загрузки (а не лениво при первом обращении в `build()`) — обнаружена и исправлена реальная лазейка: `.cast()` без `.toList()`/итерации ничего не проверяет сразу. `ProbePruefungScreen._buildPlan` (ранее вызывался без try/catch внутри `setState`) теперь безопасно деградирует к прежнему плану/`kursNichtGefunden`. Добавлено обратно совместимое поле `ParsedCourse.schemaVersion` (default 1). Полная типизация per-field DTO и миграции старых схем не выполнены и остаются явным следующим пунктом. 8 новых тестов. |
| CR-09/CR-10 | Закрыт по продуктовому решению пользователя | Пользователь выбрал: (1) fail-open для всех исходов кроме подтверждённого `200 {allowed:false}` — 401/403/5xx/timeout теперь различаются в диагностике (`debugPrint`), но исход остаётся `allowed`; (2) убрать device-gate с блокирующего пути холодного старта. `prepareAppStartup()` больше не `await`-ит проверку; `redirect` в `app.dart` инициирует её в фоне (`_ensureDeviceGateChecked`) и делает `router.go('/device-limit')` только по факту подтверждённого лимита. `forceRegisterCurrentDevice()` теперь возвращает `bool` (реальный статус), UI лимита показывает ошибку и не переходит на Home при неуспехе — раньше любая ошибка молча трактовалась как успех. 10 новых тестов (`device_service_test.dart`). |
| CR-11 | Закрыт для основного money-path (импорт PDF) | Новый `ApiException` (`lib/services/api_exception.dart`) с `kind`/`statusCode`/`retryable`; `debugDetails` содержит только context/status/размер, raw response body исключён и из диагностики, и из UI. `ParseService.convertPdf/convertPdfFile/parseSection` бросают типизированную ошибку вместо `Exception('...${res.body}')`; `_parseWithRetry` читает `statusCode` напрямую вместо хрупкого regex по тексту сообщения. `ImportScreen` показывает разный локализованный текст для 401/403/413/429/timeout вместо одного общего сообщения на все случаи; 5xx/unknown используют безопасный общий текст. 17 новых тестов (`api_exception_test.dart`, `import_screen_api_error_test.dart`). |
| CR-12 | Закрыт | Удалены `READ_EXTERNAL_STORAGE`/`READ_MEDIA_IMAGES` (SAF-пикер файла ничего из этого не требует — подтверждено манифестом самого плагина `file_picker`, который не декларирует ни одного storage-разрешения). Добавлен `android:allowBackup="false"`: локальные курсы — только зеркало Firestore (см. cross-device merge в `loadAll()`), автоматический backup не даёт продуктовой пользы и рисковал бы пережить удаление аккаунта в устаревшем снапшоте Google Backup. `android:label` заменён с технического `exam_trainer` на `Exam Trainer` (подтверждено в собранном APK через `aapt2 dump badging`). 3 новых теста (`manifest_privacy_test.dart`). |

Итого добавлено 174-132=42 новых теста поверх P0 baseline (132 → 174,
`flutter test --coverage` 1825/4364 строк, 41,82%). `flutter analyze` и
`dart format --set-exit-if-changed .` чистые. Production release APK
пересобрана из текущего кода: `com.linguaproapps.exam_trainer`,
versionCode 10, versionName 1.0.0, сертификат `CN=Exam Trainer`
(SHA-256 сертификата `84a3677cc24c58160c9fe3a9ce4befa09d204f7056d5efc4e795948850a92ea4`),
и в собранном APK подтверждена метка `Exam Trainer` вместо `exam_trainer`.
Изолированная сборка без `key.properties` (в копии вне репозитория, без
signing-файлов) снова корректно упала с понятной `GradleException`.
`git diff --check` чист.

Device integration smoke выполнен после подключения физического устройства
позже в этой же сессии: `tool/run_android_integration.sh <device-id>` прошёл
1/1 на Samsung SM-S938B (`RFCY51N8PEK`). После теста на устройстве
подтверждены `pm path com.linguaproapps.exam_trainer` (production package
на месте, `versionCode=10`, `versionName=1.0.0`) и отсутствие
`com.linguaproapps.exam_trainer.integration` — интеграционный пакет удалён,
как и предусмотрено скриптом. Это подтверждает device smoke, но не означает
полное закрытие CR-08: typed DTO/migrations остаются следующей задачей.

Остаточные риски после P1:
- CR-07: полноценное conflict resolution между устройствами (revision/updatedAt)
  требует backend-контракта — сознательно не реализовано, задокументировано,
  ждёт решения пользователя;
- CR-08: только input-границы, реально используемые главным flow, получили
  defensive casts; per-field type confusion внутри уже провалидированных
  списков (например, число вместо строки в одном поле вопроса) и полная
  типизация DTO остаются как в исходном отчёте;
- CR-09/CR-10: device id остаётся идентификатором установки, а не аппаратным
  идентификатором. Backend force-replace не транзакционен: промежуточный сбой
  после удаления части старых записей возвращает честный `{ok:false}`, повтор
  безопасен, но операция может быть частично выполнена;
- CR-12: `dataExtractionRules`/более гранулярная backup-политика не введены
  — выбран полный `allowBackup="false"` как самое простое и однозначно
  безопасное решение.

### Независимая перепроверка результата P1

Повторный аудит выявил и исправил регрессии первой реализации:

- [x] enqueue во время активного flush больше не перезаписывается старым
  snapshot: outbox-операции имеют стабильный `operationId`, а все mutation
  сериализованы и применяются к свежему состоянию;
- [x] зафиксированный для UID A flush не может получить токен UID B; смена
  аккаунта до/во время auth отменяет отправку, операция A остаётся в outbox;
- [x] retry работает автоматически по таймеру и вручную с карточки курса;
  повреждённый outbox сохраняется под quarantine-ключом;
- [x] account deletion сначала приостанавливает sync и ждёт активный request,
  поэтому старый upload не может завершиться после удаления и воскресить курс;
- [x] `200 {}`/null/string от `/api/device` fail-open, limit подтверждается
  только точным boolean `allowed:false`; устаревший ответ старого UID не меняет
  router state новой сессии;
- [x] force-device и course-delete подтверждаются только при реальном успехе
  Firestore. Форма endpoint сохранена, failure теперь `503 {ok:false}`;
- [x] raw backend response удалён даже из `ApiException.debugDetails`;
- [x] CR-08 переклассифицирован из «закрыт» в «частично закрыт», поскольку
  defensive casts не заменяют полную типизацию DTO/migrations.

Итоговые gates после перепроверки: Flutter format/analyze чистые, 191/191
тестов, coverage 1972/4503 строк (43,79%); backend 72/72 теста и `py_compile`;
production release APK собрана (`com.linguaproapps.exam_trainer`, 1.0.0+10),
подписана `CN=Exam Trainer`, а изолированная сборка без `key.properties`
fail-closed с exit 1 и понятным сообщением. Device smoke в этой перепроверке не
повторялся, потому что `adb devices -l` не показал подключённого устройства;
предыдущий защищённый прогон 1/1 на Samsung остаётся последним фактическим.
Реализация сохранена Flutter-коммитом `c61fa88`, правдивые backend
подтверждения — коммитом `5495185`; production backend не развёртывался.

Самодостаточная передача состояния, ограничений, безопасных команд и готовый
промт для агента, продолжающего дальше, сохранены в
[`NEXT_AGENT_PROMPT.md`](NEXT_AGENT_PROMPT.md). Handoff отдельно предупреждает
о локальном P0 baseline-коммите `276afdb`, архивном pre-P0 AAB и запрете прямого
device `flutter test`, который может удалить production package и его локальные
данные.
