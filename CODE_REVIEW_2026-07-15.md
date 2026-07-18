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

### P2 (CR-08 завершение, CR-13—CR-16) — обновлено 15 июля 2026

| ID | Статус | Реализация и проверка |
|---|---|---|
| CR-08 | Закрыт (усилен после независимой перепроверки — см. ниже) | Введены typed immutable DTO для всех 12 типов упражнений: [`exercise_common.dart`](lib/models/exercises/exercise_common.dart) (общие type-checked helpers `asString`/`asInt`/`asList`/... — намеренно НЕ nullable-cast `as T?`, чтобы неправильный тип поля деградировал к безопасному значению, а не бросал `TypeError`), [`universal_variant.dart`](lib/models/exercises/universal_variant.dart) (9 типов, использующих `_validateUniversal`-схему parse_service), [`sprachbausteine1_variant.dart`](lib/models/exercises/sprachbausteine1_variant.dart), [`telefonnotiz_variant.dart`](lib/models/exercises/telefonnotiz_variant.dart), [`hoeren_teil1_variant.dart`](lib/models/exercises/hoeren_teil1_variant.dart). Все 6 exercise screens (`universal_exercise_screen.dart`, `beschwerde_exercise_screen.dart`, `sprachbausteine_exercise_screen.dart`, `sprachbausteine2_exercise_screen.dart`, `telefonnotiz_exercise_screen.dart`, `hoeren_teil1_exercise_screen.dart`) читают эти DTO вместо `Map<String,dynamic>`/`cast<...>()`. Обратная совместимость: старый (v1, без `schema_version`) и текущий формат курса читаются одним и тем же кодом — никаких изменений backend/cache schema не потребовалось. Прежние CR-08-регрессионные фикстуры с «одним повреждённым элементом списка» обновлены: после defensive parsing это больше не крашится (`.whereType<Map>()` просто пропускает плохой элемент) — оставлен только реальный boundary («сам вариант — не Map»). **Изначально структурное поле-идентификатор `number` молча дефолтилось в 0 при отсутствии/неверном типе — независимая перепроверка нашла в этом реальный баг (см. подраздел ниже); после исправления и расширения legacy-фикстуры до всех 12 типов раздел честно закрыт.** |
| CR-13 | Продолжен: Import уже был готов ранее, добавлен общий Course/Exercise loader | Новый [`variant_loader.dart`](lib/ui/features/exercise/variant_loader.dart): `loadVariant<T>({courseLoader, courseId, sectionType, index, fromJson})` возвращает `VariantLoadResult<T>` (`.loaded`/`.notFound`/`.error`), заменяя ~120 строк почти идентичного boilerplate, дублированного в 6 экранах (загрузка курса → поиск по id → проверка index → cast варианта → построение DTO → `mounted`-safe `setState`). Каждый экран сохранил свою post-processing логику поверх общего loader (например, Beschwerde сортирует вопросы, Sprachbausteine оборачивает `_initExercise()` в try/catch, сохраняя прежнюю семантику «любая ошибка здесь тоже error state»). Новый state-management framework не добавлен — используется тот же `setState`/`StatefulWidget`, что и раньше. 6 тестов (`test/ui/features/exercise/variant_loader_test.dart`). Остаток CR-13 (полный переход остальных экранов, помимо Import и загрузки упражнений, на Controller/ViewModel/Repository) не сделан и остаётся в объёме исходной рекомендации. Не тронут в сессии независимой перепроверки ниже. |
| CR-14 | Закрыт после четырёх раундов независимой перепроверки — см. ниже | `TtsService._dir` теперь использует `getApplicationCacheDirectory()` вместо `Documents` — это кэш, полностью восстановимый через `_synthesize()`, поэтому безопасно эвиктится ОС и не должен попадать в Android backup/подсчёт «данных приложения» (согласуется с CR-12 `allowBackup=false`). Добавлен предел `_maxCacheBytes = 200 MiB`, LRU-эвикция (по `mtime`, обновляемому при каждом cache-hit) с trim до 90% лимита, атомарная запись через `<key>.mp3.tmp` + rename (тот же паттерн, что уже используется в `CourseStorage`), sweep осиротевших `.tmp` файлов старше минуты, одноразовая best-effort очистка унаследованного `Documents/tts_cache`. Последующие раунды исправили cross-key eviction, гарантию существования возвращаемого пути, lifecycle плеера и ownership: `ensureAudio()` возвращает уникальный `TtsAudioLease`, `release()` идемпотентен для конкретного владельца, а cache mutation/clear/eviction сериализованы и не удаляют путь с чужим активным lease. |
| CR-15 | Частично закрыт: устранён самый заметный разрыв, полный аудит не завершён | `dialogue_audio_player.dart` (используется 3 экранами) был единственным местом со смешанным жёстко заданным немецким/русским текстом одновременно — полностью локализован через новые геттеры в `lib/l10n/strings.dart` (`dialogAnhoeren`, `pausieren`, `weiterhoeren`, `audioWirdGeneriert`, `textDialog`, `textAufnahme`, `audioNeuGenerieren`, `wiederholenAction`, `fehlerBeimGenerieren`). По ходу исправления обнаружен и устранён дополнительный CR-11-класса баг: поле `_error` хранило сырой текст исключения (`e.toString()`) и никогда не выводилось на экран только по счастливой случайности пути кода — теперь поле удалено полностью, всегда показывается только `s.fehlerBeimGenerieren`. `Semantics` добавлены: transcript toggle (`button`/`label`/`toggled`, с `excludeSemantics: true`, чтобы не дублировать label с видимым текстом — Flutter иначе склеивает оба через `\n` в один announcement), play/pause-иконка (`label` меняется по состоянию), live-region на статусный label. `_AnswerButton` (universal_exercise_screen) получил touch target 36dp→48dp и `Semantics`. Такой же паттерн (`Semantics` + `excludeSemantics` + `ConstrainedBox(minHeight: 48)`) применён к `_mcOption` (hoeren_teil1_exercise_screen) и `_OptionTile` (beschwerde_exercise_screen); `_ScoreChip` (beschwerde) получил `liveRegion: true`, поскольку появляется только после отправки ответов и должен быть озвучен screen reader без ручного поиска. 3 новых теста (`test/widgets/dialogue_audio_player_test.dart`): idle label следует locale, а не жёстко заданной строке; transcript toggle имеет реальный accessibility label; ошибка синтеза никогда не показывает сырой текст исключения. **Не сделано и явно отложено**: `DropdownButton` в `_GapWidget` (обе `sprachbausteine*_exercise_screen.dart`) — стандартный Material-виджет уже имеет базовую a11y, но не объявляет, к какому именно пропуску (gap N) он относится; полный TalkBack-прогон на реальном устройстве и font-scale 200% визуальная проверка не выполнялись (не было устройства в этой сессии — `adb devices` пуст). CR-15 не является полностью закрытым. Не тронут в сессии независимой перепроверки ниже. |
| CR-16 | Частично: patch/minor семейство Firebase обновлено, major-обновления оценены и осознанно отложены | `flutter pub upgrade` (без `--major-versions`) поднял `firebase_auth` 6.5.4→6.5.6, `firebase_core` 4.11.0→4.12.1, `uuid` 4.5.3→4.6.0 и их транзитивные зависимости в рамках уже существующих caret-констрейнтов в `pubspec.yaml` — без правки самого файла. Полный gate (`flutter analyze`, `flutter test`, release APK build) пройден без изменений в коде. Остальные major-апгрейды сознательно НЕ выполнены в этой сессии: `go_router` 13→17 (4 major-версии, вероятны breaking changes в роутинге, затрагивающем весь `app.dart`), `google_fonts` 6→8, `device_info_plus` 10→13 (используется в device-gate — центральной security-функции, см. CR-09/CR-10). `file_picker` заблокирован намеренно и не должен обновляться без отдельной проверки: коммит истории репозитория (`c53c20c`) зафиксировал, что 11.x ломается на Kotlin/AAR class-not-found с текущим Flutter toolchain, а retracted-версия 10.3.11 недоступна на pub.dev — пин на точную `10.3.10` в `pubspec.yaml` это фиксирует намеренно, не случайный застой. При production release build Gradle предупредил, что `device_info_plus`/`file_picker` применяют устаревший способ подключения Kotlin Gradle Plugin и будущие версии Flutter могут перестать собираться с этими версиями плагинов — дополнительный аргумент за то, чтобы обновление `device_info_plus` было отдельной, тщательно протестированной задачей, а не частью этой сессии. |

Итого добавлено 233-191=42 новых теста поверх P1 baseline (191 → 233,
`flutter test --coverage` 2284/4644 строк, 49,18%). `flutter analyze` и
`dart format --set-exit-if-changed .` чистые. Backend не изменялся в этой
сессии (0 diff), его 72/72 теста и `py_compile` подтверждены повторным
прогоном через временный venv (в репозитории venv отсутствовал, установлен
из `requirements.txt` во временный каталог, в репозиторий не добавлен).
Production release APK пересобрана из текущего кода
(`app-production-release.apk`, 59.2MB), `git diff --check` чист на обоих
репозиториях. Device integration smoke **не выполнялся** в этой сессии —
`adb devices` не показал подключённого устройства; последний фактический
защищённый прогон остаётся тем же, что описан в P1-разделе выше (Samsung
SM-S938B, 1/1).

Ни backend API, ни production endpoint, ни формат `ParsedCourse`, ни
Free/Premium-ограничения, ни UID-изоляция, ни Firebase Auth не изменялись.
Изменения ограничены Flutter-клиентом: новые DTO-модели, общий loader,
TTS-cache, локализация/accessibility нескольких виджетов и patch/minor
dependency bump.

Честная сводка незакрытого после этой сессии: CR-13 (остальные экраны, кроме
Import и exercise loading, всё ещё обращаются к сервисам напрямую), CR-15
(DropdownButton gap-labeling, реальный TalkBack/font-scale 200% прогон на
устройстве), CR-16 (все four major-апгрейда: go_router, google_fonts,
device_info_plus, file_picker) остаются как задокументированная следующая
работа — не заявлены закрытыми.

### Независимая перепроверка P2 (CR-08/CR-14): устранение блокирующих замечаний — 15 июля 2026

Независимая проверка результата предыдущей P2-сессии дала вердикт
**REQUEST CHANGES** по двум пунктам главного блокера и одному пункту CR-14;
все перечисленные замечания разобраны и исправлены ниже, с тестами и полным
gate. Работа велась поверх незакоммиченного состояния предыдущей сессии —
ничего не откачено и не перезаписано.

**1. Конкурентная запись TTS-кэша (главный блокер).**
`TtsService.ensureAudio` использовал один и тот же `<key>.mp3.tmp` для двух
параллельных запросов одинакового аудио: обе записи целились в один
временный файл, и чей-то `rename()` уже мог унести файл из-под второго —
`PathNotFoundException`. Исправление в
[`tts_service.dart`](lib/services/tts_service.dart):
`_pendingByKey` (`Map<String, Future<String>>`) сериализует ВСЕ операции
(включая `forceRegenerate`) по одному и тому же ключу — второй конкурентный
вызов не запускает собственную запись параллельно, а встраивается в цепочку
после первого (`previous.then(..., onError: ...).then(() => _ensureAudioOnce(...))`),
поэтому реальная запись `<key>.mp3.tmp` в любой момент времени только одна.
`_ensureAudioOnce` дополнительно оборачивает запись+rename в try/catch:
при ошибке удаляется только свой временный файл (best-effort), финальный
файл никогда не остаётся частично записанным, ошибка пробрасывается дальше
(`rethrow`), а не маскируется. Публичная сигнатура `ensureAudio`, формат
ключей кэша (`sha1(speaker|text)`) и путь `<dir>/<key>.mp3` не менялись.
Найден и устранён смежный баг во время реализации: `Future.whenComplete()`
возвращает собственный производный Future, зеркалящий ошибку исходного —
без `.ignore()` на нём неудачная операция репортилась как ВТОРОЕ,
паразитное необработанное исключение, даже когда сам `operation`
(реально возвращаемый вызывающему) был корректно обработан. 4 новых теста
в `test/services/tts_cache_test.dart` (`group('concurrent ensureAudio
calls')`): два параллельных запроса одной `DialogueLine` дают один и тот же
путь и ровно ОДИН HTTP-вызов (дедуп, не просто отсутствие краша);
`forceRegenerate`, пришедший во время уже идущего обычного вызова,
сериализуется (2 вызова, оба валидны, второй — реальная регенерация, не
проигнорирован); три параллельных запроса РАЗНЫХ `DialogueLine` не мешают
друг другу (3 независимых файла); неудача одного конкурентного вызова
(сброс 500) не портит файл, на который ждёт второй — второй получает
валидный committed clip, `.tmp` не остаётся.

**2. Lifecycle `DialogueAudioPlayer`.**
Повторный вызов `_start()`/`_regenerate()` мог пересечься с предыдущей
асинхронной операцией: устаревшая цепочка `await`-ов после dispose могла
вызвать `setState` на снятом `State` или запустить воспроизведение поверх
уже отменённого запроса. Исправление в
[`dialogue_audio_player.dart`](lib/widgets/dialogue_audio_player.dart):
единый `_opToken` (заменил прежний более узкий `_playToken`) увеличивается
в `_start()`, `_regenerate()`, `_stop()` и `dispose()`; каждая точка после
`await` в `_start`/`_playFrom` проверяет `!mounted || token != _opToken`
перед `setState`, воспроизведением или мутацией состояния — устаревшая
операция молча завершается, не трогая UI. `_start()` и `_regenerate()`
дополнительно блокируют повторный вход, пока `_state == preparing`
(регенерация во время подготовки: кнопка `IconButton` отключена в
`_buildBar()` через `onPressed: null`, и `_regenerate()` содержит тот же
guard на уровне кода — двойная защита). `_cycleSpeed()` (изменение скорости
воспроизведения) получил проверку `mounted` после `await
setPlaybackRate` перед `setState` — раньше её не было. `_playFrom` также
оборачивает `_player.play()` в try/catch (плеер мог быть уже disposed,
если продолжение резюмируется после unmount) и трекает
`_onCompleteSub`, чтобы предыдущий незавершённый completion-listener не
мог повторно продвинуть воспроизведение параллельно с новым. Отдельно
исправлена семантика: в состоянии `paused` иконка озвучивалась как
`s.dialogAnhoeren` («прослушать диалог») вместо `s.weiterhoeren`
(«продолжить») — `_leadingIcon` теперь использует тот же `switch` по
состоянию, что уже был в `_label()`. 3 новых теста в
`test/widgets/dialogue_audio_player_test.dart` (`group('lifecycle')`):
dispose во время preparing не бросает исключений и не применяет
устаревшее состояние, когда гейтированный HTTP-ответ наконец приходит
(проверено через `tester.takeException()`); кнопка regenerate отключена
во время preparing; монтирование нового инстанса плеера после того, как
предыдущий был disposed на середине подготовки, стартует чистую
независимую операцию, не задетую устаревшим продолжением первого
(«повторный запуск» / repeated-launch путь — навигация с экрана и обратно).
Прямой end-to-end прогон `_regenerate()`/воспроизведения через реальный тап
в этом test harness не тестировался: `audioplayers`' метод/event channels
не замоканы в `flutter test` (подтверждено пробой — `AudioPlayer().stop()`
без платформенной регистрации бросает `MissingPluginException` даже без
предыдущего `play()`), поэтому тест на «retry после ошибки» пришлось
заменить на «повторный запуск после dispose», не задевающий плеер напрямую;
это ограничение test harness, не код-дефект, и совпадает с тем, что
предыдущая сессия тоже никогда не доводила `DialogueAudioPlayer`-тесты до
реального `playing`-состояния.

**3. Legacy TTS-кэш (`Documents/tts_cache`) — устранение неполноты CR-14.**
Добавлен `TtsService._cleanupLegacyCacheOnce()`: при первом обращении к
`_dir` в рамках процесса удаляет ровно
`getApplicationDocumentsDirectory()/tts_cache` (точный прежний путь, ничего
шире), если он существует; ошибка любого рода (нет прав, гонка с другим
процессом) перехватывается и не мешает основному TTS-сценарию — cleanup
best-effort и повторится на следующем запуске (флаг `_legacyCleanupDone`
только в памяти, не персистентный). 4 новых теста в
`test/services/tts_cache_test.dart` (`group('legacy Documents/tts_cache
cleanup')`): унаследованный каталог с файлом внутри удаляется, а соседний
неродственный файл в `Documents` остаётся нетронутым; отсутствие каталога
не вызывает ошибку; принудительно смоделированная (через тестовый seam
`debugForceLegacyCleanupFailure`, детерминированно, без завязки на
специфику файловой системы) storage-ошибка не ломает основной сценарий;
повторный запуск cleanup после того, как каталог уже пуст, безопасен.

**4. CR-08: доработка defensive parsing.**
`ExerciseQuestion.number` (используется как ключ answer/lookup карт
буквально во всех exercise screens — `_selected[q.number]`,
`_questionsByNumber = {for (final q in v.questions) q.number: q}`,
`_rfAnswers[rf.number]`, `_mcAnswers[mc.number]`) раньше дефолтился в `0`
через общий `asInt()` при отсутствии/неверном типе поля. Два вопроса без
`number` (или с нечисловым `number`) молча превращались в одинаковый `#0`
и схлопывались в ОДНУ запись в карте ответов — упражнение при этом
успешно «загружалось», но реально теряло один вопрос без какой-либо
ошибки. Это и есть регрессия «два вопроса превращались в №0», которую
проверка попросила явно закрыть. Введена чёткая политика (реализована в
[`exercise_common.dart`](lib/models/exercises/exercise_common.dart)):
структурные поля, от которых зависит идентификация/подсчёт/завершение
(`ExerciseQuestion.number`, `RichtigFalschQuestion.number`,
`MultipleChoiceQuestion.number` в `hoeren_teil1_variant.dart`), теперь
парсятся через новый `asRequiredInt()`, который бросает
`ExerciseSchemaException` вместо дефолта; `listFromJson`/`fromJson` также
проверяют уникальность номеров через `assertUniqueNumbers()` (для
hoeren_teil1 — раздельно для richtig_falsch и multiple_choice, поскольку
экран хранит их в разных картах). Presentation-поля (`text`, `type`,
`options`, `topic`, `version`, `title`, ...) остаются мягко дефолтящимися,
как и раньше — политика узкая и целенаправленная, не переписывает весь
файл. Все брошенные исключения перехватываются существующим
`loadVariant()` (`variant_loader.dart`), который уже конвертирует любое
исключение из `fromJson` в `VariantLoadResult.error()` — ошибка попадает в
уже существующий error/not-found UI (см. CR-04), а не в бесконечный
spinner и не в raw Exception на экране; новый код специально ничего не
меняет в этом маршруте. Schema v1 и существующие валидные legacy-фикстуры
остаются совместимыми (подтверждено полным прогоном
`legacy_course_migration_test.dart` без изменений в самих фикстурах кроме
расширения, см. ниже) — только по-настоящему повреждённые/отсутствующие
поля теперь дают ошибку вместо тихого искажения данных. 4 новых/изменённых
теста в `test/models/exercises/exercise_dto_test.dart` покрывают именно
этот сценарий: отсутствующий/нечисловой `number` бросает; дубликат `number`
в списке бросает; список с валидными вопросами и ОДНИМ вопросом без
`number` бросает целиком (а не тихо теряет один вопрос); аналогичный
дубликат-тест добавлен для `HoerenTeil1Variant.richtig_falsch`.

Проверены оставшиеся dynamic/raw map consumers, названные в задаче явно:
- [`section_list_screen.dart`](lib/screens/section_list_screen.dart) читает
  только presentation-поля (`variant_number` с fallback на индекс списка,
  `topic`, `version`) и уже форсирует `variant as Map<String, dynamic>` для
  каждого элемента внутри `try/catch` в `_load()` до `setState` — один
  повреждённый элемент списка уже переводит экран в error state, а не
  крашит скролл. Навигация (`context.push('/course/.../$i')`) использует
  индекс списка, а не какое-либо поле из JSON, поэтому коллизии
  идентификации в принципе невозможны для этого экрана.
- [`probe_pruefung_screen.dart`](lib/screens/probe_pruefung_screen.dart)`_buildPlan`
  аналогично читает только `variant_number` (fallback на индекс) для
  подписи, каждый вызов уже обёрнут в `try/catch` (в `_load()` и
  `_regenerate()`), деградирующий к `kursNichtGefunden`/прежнему плану.
  Прогресс (`visited`) и маршрут (`route`) индексируются по позиции в
  списке `_parts`, не по JSON-полю.

  Оба экрана признаны безопасными «как есть»: перевод их на typed DTO
  добавил бы отдельную summary-абстракцию поверх всех 12 разных схем ради
  трёх presentation-полей без индекс-ориентированной логики — это не
  минимальное изменение и не устраняет какой-либо реальный дефект. Решение
  задокументировано, а не сделано молча.

Legacy-fixture (`test/models/legacy_course_migration_test.dart`) расширена
с 10 до всех 12 заявленных типов упражнений — добавлены `lesen_teil3` и
`lesen_teil4` (тот же universal-schema путь, что уже покрыт для
`lesen_teil1`/`lesen_teil2`), `course.sections.keys` теперь ожидается
`hasLength(12)`.

**Полный gate после исправлений:**
`dart format --output=none --set-exit-if-changed .` чист;
`flutter analyze` — `No issues found!`; `flutter test` — 248/248 (было 233,
+15 новых тестов: `tts_cache_test.dart` 6→14 (+8: 4 concurrency + 4
legacy-cleanup), `dialogue_audio_player_test.dart`
3→6 (+3 lifecycle), `exercise_dto_test.dart` 21→25 (+4 structural-field
validation); `test/models/legacy_course_migration_test.dart` осталось 6
тестов (не добавлены новые, но фикстура расширена до 12 типов, см. выше).
`flutter test --coverage` —
2334/4703 строк (49,63%, было 49,18%); backend — 72/72 теста и
`py_compile` чисты (backend не менялся в этой сессии, 0 diff со стороны
данного агента; предсуществующий незакоммиченный diff `PRODUCT_PLAN.md` в
`exam-trainer-api` от предыдущей сессии не тронут); `git diff --check`
чист в обоих репозиториях. Device integration smoke **выполнен**: телефон
Samsung SM-S938B (`RFCY51N8PEK`) был подключён,
`tool/run_android_integration.sh RFCY51N8PEK` прошёл 1/1
(`pdf_course_smoke_test.dart`), после теста подтверждены `pm path
com.linguaproapps.exam_trainer` (production package на месте) и отсутствие
`com.linguaproapps.exam_trainer.integration`. Этот smoke не специфичен для
TTS/audio — отдельного integration-теста на воспроизведение аудио в
репозитории нет (см. ограничение test harness выше).

Ни backend API, ни production endpoint, ни формат `ParsedCourse`, ни
ключи/формат TTS-кэша, ни Free/Premium-ограничения, ни UID-изоляция, ни
Firebase Auth не менялись. Изменения ограничены Flutter-клиентом:
`tts_service.dart`, `dialogue_audio_player.dart`, `exercise_common.dart`,
`hoeren_teil1_variant.dart`, `lib/l10n/strings.dart` (без изменений
значений строк — только использованы существующие геттеры) и
соответствующие тесты.

Честная сводка незакрытого после этой сессии (не изменилось относительно
предыдущей P2-сессии, кроме CR-08/CR-14 выше): CR-13 (остальные экраны,
кроме Import и exercise loading, всё ещё обращаются к сервисам напрямую),
CR-15 (DropdownButton gap-labeling, реальный TalkBack/font-scale 200%
прогон на устройстве — устройство было доступно в конце этой сессии, но
задача не входила в её объём), CR-16 (все четыре major-апгрейда: go_router,
google_fonts, device_info_plus, file_picker) остаются как
задокументированная следующая работа.

Реализация этой сессии сохранена Flutter-коммитом `be13141` (branch
`phase5-account-deletion`).

### Второй раунд независимой перепроверки P2 (CR-14): concurrent eviction и DialogueAudioPlayer play-error state — 15 июля 2026

Независимая проверка запушенных коммитов `be13141`/`85586c8` нашла два
новых, ранее не обнаруженных дефекта — один HIGH (данные), один MEDIUM
(UX/lifecycle). До их исправления CR-14 не может считаться полностью
закрытым, несмотря на предыдущую формулировку «Закрыт». Оба разобраны и
исправлены в этом раунде, поверх уже запушенного состояния (без rebase,
force push или переписывания истории — отдельный follow-up commit).

**1. HIGH — конкурентная LRU-эвикция TTS-кэша.**

Первый раунд перепроверки уже сериализовал `ensureAudio()` для ОДНОГО и
того же ключа через `_pendingByKey` — это устранило гонку за общий
`<key>.mp3.tmp`. Но `_enforceCacheBudget()` вызывалась независимо каждым
успешным commit, БЕЗ синхронизации МЕЖДУ разными ключами: два
одновременных commit'а разных `DialogueLine` каждый брали собственный
снимок каталога (`dir.list()`), оба видели один и тот же «over budget»
итог и оба независимо решали удалить файл — иногда один и тот же (второй
delete падал на несуществующем файле, best-effort catch молча его
проглатывал, НЕ уменьшая локальный счётчик totalBytes второго прохода —
поэтому второй проход, всё ещё «думая», что кэш переполнен, шёл дальше и
удалял ВТОРОЙ файл тоже). Результат: при лимите 1000 байт и двух clips по
600 байт (для соблюдения лимита достаточно удалить один) итоговый кэш мог
остаться вообще пустым, хотя оба `ensureAudio()` вернули «успешные» пути.

Детерминированный репро (`TtsService.debugMaxCacheBytesOverride = 1000`,
два параллельных `ensureAudio()` разных ключей по 600 байт) подтверждён
до исправления: тест падал систематически (проверено 6 прогонов подряд,
0/6 стабильных).

**Модель синхронизации.** В [`tts_service.dart`](lib/services/tts_service.dart)
добавлена вторая, более широкая очередь `_evictionChain`
(`Future<void>`), отдельная от уже существующей `_pendingByKey`:

- `_pendingByKey` по-прежнему сериализует ВСЕ операции ОДНОГО ключа
  (включая `forceRegenerate`) — не тронуто.
- `_evictionChain` сериализует commit+evict хвост ЛЮБОГО ключа: после
  успешной записи `<key>.mp3.tmp` → rename, вызов `_enforceCacheBudget`
  теперь идёт через `_commitAndEnforceBudget(path)`, который встраивает
  проход в общую цепочку — гарантируя, что в любой момент времени
  выполняется РОВНО один eviction-проход, и каждый проход видит
  актуальное состояние каталога, оставленное предыдущим (а не устаревший
  собственный снимок).
- Синтез (`_synthesize()`, сетевой HTTP-вызов) остаётся ВНЕ этой очереди
  и по-прежнему выполняется параллельно для разных ключей — сериализован
  только быстрый, безсетевой commit+evict хвост.

**Гарантия для возвращаемых файлов.** Одной глобальной сериализации
недостаточно самой по себе: если проход A (триггернутый коммитом ключа A)
оказывается ИМЕННО тем проходом, который находит кэш переполненным и по
LRU-oldest-first выбирает для удаления... собственный только что
записанный файл A (легитимный сценарий, если A оказался «старше» B к
моменту прохода) — `ensureAudio()` для A вернул бы путь к файлу, который
его же собственный (ожидаемый им) eviction-проход только что удалил.
Поэтому `_enforceCacheBudget` получил параметр `exclude`: путь, который
ИМЕННО ЭТОТ проход только что закоммитил, учитывается в общем размере, но
никогда не выбирается кандидатом на удаление в РАМКАХ ЭТОГО прохода. Файл,
эвиктнутый ПОЗДНЕЕ отдельным проходом другого (уже вернувшегося) вызова —
нормальное поведение LRU-кэша, не баг: тот вызов уже получил валидный файл
в момент своего возврата.

Итог: для двух ключей по 600Б при лимите 1000Б (target 900Б после 90%
trim) — ровно один файл эвиктится, ровно один выживает, оба
`ensureAudio()` детерминированно резолвятся без исключений. Для трёх
ключей по 600Б при лимите 1400Б (target 1260Б) — ровно один эвиктится,
ровно два выживают. Временного превышения лимита сверх одного файла не
возникает: каждый commit немедленно сопровождается полным,
непротиворечивым eviction-проходом.

**Обработка ошибок.** `_enforceCacheBudget` теперь целиком обёрнут в
try/catch (ошибка листинга каталога — best-effort, не ломает TTS и не
«отравляет» `_evictionChain` навсегда для последующих commit'ов);
индивидуальные ошибки `delete`/`stat` по-прежнему best-effort, как и
раньше.

**Regression-тесты** в `test/services/tts_cache_test.dart`
(`group('concurrent LRU eviction across different keys')`):

1. два конкурентных commit'а разных ключей по 600Б при лимите 1000Б —
   ровно один файл выживает (не ноль, не два), итоговый размер ≤ лимита,
   `.tmp` отсутствует, оба Future резолвятся без исключений, повторный
   запрос эвиктнутого ключа корректно ресинтезирует его заново (проверено
   явным вторым `ensureAudio()` вызовом);
2. три конкурентных commit'а по 600Б при лимите 1400Б — ровно два файла
   выживают (не три, не меньше двух), `.tmp` отсутствует.

Оба теста **проверены как настоящий regression**: временный откат
`_commitAndEnforceBudget` на прямой (несериализованный) вызов
`_enforceCacheBudget()` воспроизвёл падение обоих тестов на 6/6 прогонах;
после восстановления исправления — 6/6 стабильных прогонов. Существующие
same-key/`forceRegenerate`/failure-recovery/legacy-cleanup тесты (все 12
прежних) продолжают проходить без изменений.

**2. MEDIUM — `DialogueAudioPlayer` застревал в ложном `playing`.**

`_playFrom()` переводил `_state` в `playing` ДО вызова
`_player.play(DeviceFileSource(...))`; если `play()` бросал исключение
(отсутствующий/повреждённый файл — в том числе ирония судьбы: файл,
только что эвиктнутый багом №1 выше, — сбой декодера, любая другая
платформенная ошибка), исключение перехватывалось и МОЛЧА
игнорировалось (`catch (_) { return; }`). Для mounted и актуального
token виджет оставался показывать «playing» бар (спидометр скорости,
seek-бар, паттерн иконки паузы) — без звука и без выхода в error state.
`setPlaybackRate()` вообще не была обёрнута в try/catch — её сбой
становился необработанным async-исключением при вызове `_playFrom` из
`_jumpTo`/completion-listener (оба fire-and-forget, без await).

**Исправление** в
[`dialogue_audio_player.dart`](lib/widgets/dialogue_audio_player.dart):

- `_player.play()` и `_player.setPlaybackRate()` теперь в ОДНОМ
  try/catch внутри `_playFrom`. Если операция всё ещё актуальна
  (`mounted && token == _opToken`) — переход в `_PlayerState.error`
  (тот же generic-локализованный `s.fehlerBeimGenerieren`, что и всюду в
  классе — без raw exception, пути файла или backend-ответа). Если
  операция устарела или виджет disposed — тихий возврат, без setState.
- Completion subscription (`_onCompleteSub`) теперь явно отменяется В
  НАЧАЛЕ `_playFrom`, до попытки play() — гарантируя, что устаревший
  listener от предыдущей строки не сработает независимо от того, успешна
  эта попытка или нет.
- `_togglePause()` (`pause()`/`resume()`), `_stop()` (`stop()`) и seek
  (`Slider.onChanged` → новый `_seek()`) были fire-and-forget без
  обработки ошибок — потенциальный источник необработанных
  async-исключений. `pause()`/`resume()` теперь используют
  `.catchError()`, переводящий в error state (с той же mounted/token
  защитой от устаревания); `stop()`/`seek()` используют
  `.catchError((_) {})`, поскольку их сбой не актуален для
  пользовательского фидбека (stop уже оптимистично переводит UI в idle;
  seek — чисто косметическая операция) — но обязаны не крашить процесс
  необработанным исключением.
- `_cycleSpeed()` (изменение скорости воспроизведения) получила
  аналогичный try/catch вокруг `setPlaybackRate` с переходом в error
  state при сбое (раньше не имела вообще никакой обработки ошибок).

**Injectable audio-player adapter** — минимальный тестовый seam, не
архитектурная перепись: `AudioPlayerAdapter` (публичный abstract class с
ровно тем набором методов/стримов, который виджет реально использует —
`play`/`setPlaybackRate`/`pause`/`resume`/`stop`/`seek`/`dispose`/3
стрима) с `_RealAudioPlayerAdapter` (приватная реализация, 1:1 делегирует
в настоящий `package:audioplayers`' `AudioPlayer`) как единственной
production-реализацией. `DialogueAudioPlayer` получил новый опциональный
`@visibleForTesting` параметр `debugPlayerFactory` (`null` по умолчанию →
`_RealAudioPlayerAdapter()`, поведение в проде не меняется — направление
UI → service сохранено, никакого нового state-management framework).
Причина необходимости: `audioplayers`' method/event channels НЕ
замоканы в обычном `flutter test` — подтверждено прежде (см. предыдущий
раздел): даже голый `AudioPlayer().stop()` без предшествующего `play()`
бросает `MissingPluginException`, поскольку КАЖДЫЙ метод
`AudioPlayer` ждёт internal `creatingCompleter`, который проваливается
из-за отсутствия platform-регистрации в конструкторе. Это ранее
блокировало любой тест, доходящий до реального `playing`/`paused`
состояния — теперь фейковый адаптер это снимает.

**Regression-тесты** в `test/widgets/dialogue_audio_player_test.dart`
(`group('AudioPlayer failure handling')`, используют новый
`_FakeAudioPlayerAdapter`):

1. сбой `play()` (отсутствующий/невалидный файл) → generic
   localized error UI, ноль raw exception текста, виджет НЕ застревает
   на «playing» баре;
2. сбой `setPlaybackRate()` после успешного `play()` → тот же error UI
   (подтверждено, что `play()` реально успел выполниться — 1 запись в
   `playedPaths` — прежде чем rate-установка упала);
3. сбой `play()`, резолвящийся ПОСЛЕ dispose виджета → `tester.
   takeException()` пуст (нет setState after dispose, нет необработанного
   исключения) — гейтировано через `Completer` внутри фейка;
4. устаревший сбой `play()` (первая попытка), резолвящийся ПОСЛЕ того,
   как `_regenerate()` уже успешно перезапустил и довёл ВТОРУЮ попытку до
   `playing` — устаревшая ошибка НЕ перезаписывает состояние новой
   (проверено: иконка/состояние остаются `playing`, error UI не
   появляется);
5. paused-состояние реально достигнуто (тап play → тап pause) и
   подтверждено показывающим `s.weiterhoeren` («Resume» в en-locale) как
   видимый текст И accessibility label — впервые протестировано
   end-to-end благодаря фейковому адаптеру (раньше зафиксировано только
   на уровне кода, без теста, из-за той же platform-channel стены).

Тест №1 **проверен как настоящий regression**: временный откат catch-блока
`_playFrom` на старое `catch (_) { return; }` воспроизвёл его падение;
после восстановления исправления — все 11 тестов файла (6 прежних + 5
новых) стабильно проходят.

**Полный gate после обоих исправлений:** `dart format
--output=none --set-exit-if-changed .` чист; `flutter analyze` —
`No issues found!`; `flutter test` — 255/255 (было 248, +7: 2 concurrent
eviction + 5 AudioPlayer failure handling); `flutter test --coverage` —
2423/4746 строк (51,05%, было 49,63%); backend — 72/72 теста и
`py_compile` чисты, backend-код НЕ менялся этим агентом в этой сессии (0
diff; venv переиспользован из scratchpad предыдущей сессии, установлен из
`requirements.txt`, в репозиторий не добавлен); `git diff --check` чист
на обоих репозиториях. Device integration smoke **выполнен**: телефон
Samsung SM-S938B (`RFCY51N8PEK`) был подключён,
`tool/run_android_integration.sh RFCY51N8PEK` прошёл 1/1
(`pdf_course_smoke_test.dart`); после теста подтверждены `pm path
com.linguaproapps.exam_trainer` (production package на месте,
`versionCode=10`, `versionName=1.0.0`) и отсутствие
`com.linguaproapps.exam_trainer.integration`. Этот smoke по-прежнему общий
(PDF→курс→упражнение), не TTS/audio-специфичный — прямого
integration_test на реальном устройстве для eviction-гонки или
play-error пути по-прежнему нет (оба покрыты только host-side unit/widget
regression-тестами выше).

Ни backend API, ни production endpoint, ни формат `ParsedCourse`, ни
ключи/формат TTS-кэша, ни публичная сигнатура `ensureAudio`, ни
Free/Premium-ограничения, ни UID-изоляция, ни Firebase Auth не менялись.
Изменения ограничены `tts_service.dart` (эвикшн-синхронизация),
`dialogue_audio_player.dart` (play-error handling + injectable adapter) и
их тестами.

**Честный статус CR-14 после этого раунда: закрыт.** Оба дефекта,
найденные независимой перепроверкой (concurrent over-eviction,
play-error stuck-state), исправлены, детерминированно
воспроизведены-как-регрессия и протестированы. Остаточные риски:
concurrent eviction-логика не имеет прямого device/integration-теста
(только host unit-тесты с fake HTTP client и укороченными budget); реальный
`audioplayers` platform-behavior (в противовес фейковому адаптеру) на
физическом устройстве для error-путей (play failure, rate-set failure)
по-прежнему не проверялся вручную — стоит включить в следующий реальный
device smoke-прогон, если возникнет практическая возможность (например,
временно испортить кэшированный файл на устройстве и понаблюдать error
UI). CR-13/CR-15/CR-16 не изменились в этом раунде — тот же
задокументированный частичный статус, что и в предыдущем разделе.

Реализация этого раунда сохранена Flutter-коммитом `ee5c25a` (branch
`phase5-account-deletion`).

### Третий раунд независимой перепроверки P2 (CR-14): нарушенная гарантия возвращаемого пути и lease-lifecycle DialogueAudioPlayer — 16 июля 2026

Независимая проверка запушенных коммитов `ee5c25a`/`ecc4783` нашла ещё
один дефект в том же CR-14, который второй раунд не устранил полностью —
**HIGH**, данные. До его исправления заявление «CR-14 теперь честно
закрыт» из предыдущего раздела было преждевременным по тому же самому
классу проблемы (concurrent eviction), просто на другом уровне защиты.

**Проблема.** `exclude: justCommittedPath` в `_enforceCacheBudget`
защищал файл только от eviction-прохода ЭТОЙ ЖЕ операции. Более ранний
проход, запущенный commit'ом ДРУГОГО cache key и уже стоящий в очереди
`_evictionChain`, мог увидеть файл более поздней операции — уже
переименованный на диск, но чья собственная запись в очередь ещё не
случилась — и удалить его, пока эта операция ещё ожидает своей очереди.
`ensureAudio()` в этом случае резолвился путём, которого уже не
существовало на диске в момент, когда Future возвращался вызывающей
стороне — прямое нарушение единственной гарантии, ради которой вся эта
синхронизация существует.

Детерминированный репро (приведён в задаче проверки): два разных
`DialogueLine`, оба синтезируются параллельно, `debugMaxCacheBytesOverride
= 1000`, каждый Future оборачивается проверкой `File(path).exists()`
сразу после `await`. До исправления: `[false, true]` — один Future
резолвился путём, который уже не существовал. Существовавший тест
`test/services/tts_cache_test.dart` асимметрично требовал
`existsA != existsB` **сразу после** `Future.wait` — то есть сам тест
кодировал баг как ожидаемое поведение, при названии, обещающем
«both futures resolve to a valid, still-existing path».

**Модель синхронизации (выбрана из допустимых в задаче): refcounted
pin/lease с явным release.** В [`tts_service.dart`](lib/services/tts_service.dart)
добавлен `Map<String, int> _pinnedPaths` — не единичный `exclude`
конкретного прохода, а ГЛОБАЛЬНЫЙ, разделяемый между всеми операциями
набор «файлов, которые сейчас у кого-то на руках»:

- `_pin(path)` инкрементирует счётчик СИНХРОННО, без единого `await`
  между моментом, когда файл становится валидным (успешный `rename()`
  для свежей записи, либо подтверждённый `exists()`+`length()` для
  cache-hit), и моментом инкремента. Это устраняет тот же класс окна
  гонки, который второй раунд уже закрыл для «своего» прохода — но
  теперь это действует против ЛЮБОГО прохода, а не только собственного.
- `_enforceCacheBudget()` (переименован из `_commitAndEnforceBudget` +
  `exclude`-параметра) больше не принимает `exclude` — вместо этого
  ЛЮБОЙ путь, присутствующий в `_pinnedPaths`, пропускается как
  кандидат на удаление в КАЖДОМ проходе, кем бы он ни был запущен. Байты
  запинненного файла по-прежнему учитываются в общем `totalBytes` (это
  реальные данные на диске), просто он никогда не выбирается для delete.
- `releasePaths(Iterable<String> paths)` — единственный способ снять
  pin; декрементирует счётчик, а когда конкретный путь долетает до нуля,
  запускает отложенный eviction-проход через ту же `_evictionChain`
  очередь (не отдельную, несинхронизированную операцию). Вызов идемпотентен:
  путь, у которого уже нет активных pin, просто игнорируется — повторный
  release не уходит в отрицательный счётчик и не бросает.
- **Автоматического снятия pin нет**, и это осознанное решение, а не
  недосмотр: снятие в `finally` (сразу как только `_ensureAudioOnce`
  доходит до `return path`) не даёт нужной гарантии. `finally` внутри
  async-функции выполняется КАК ЧАСТЬ завершения её собственного Future;
  продолжение вызывающей стороны (`await`/`.then()`) резолвится только
  ПОЗЖЕ, отдельным microtask. Между «funcion дошла до return» и
  «вызывающая сторона реально получила управление» лежит окно, в которое
  конкурентный eviction-проход другого ключа мог бы успеть выполниться —
  тот же самый класс бага, который всё это и вызвало, просто на шаг
  позже. Поэтому lease живёт, пока явно не вызван `releasePaths()` со
  стороны реального потребителя пути, а не со стороны самого
  `TtsService`.

**Временный выход за лимит — задокументирован и доказан тестом, не
скрыт.** Пока путь кем-то удерживается (pin > 0), эвикшн не может его
тронуть, даже если это означает временное превышение `_cacheBudget`.
Это не бесконечное отключение лимита (требование 8 задачи проверки):
как только держатель вызывает `releasePaths()`, отложенный проход
приводит кэш обратно под лимит; при отсутствии дальнейшего синтеза кэш
не остаётся раздутым навечно — сам вызов `releasePaths()` детерминированно
запускает исправляющий проход, а не полагается на следующий
`ensureAudio()`.

**Потребитель: `DialogueAudioPlayer`.** До этого раунда виджет вызывал
`TtsService.instance.ensureAudio(...)` и просто хранил возвращённые пути
в `_paths` — никакого понятия о lease не было, поэтому весь смысл нового
API в `TtsService` был бы бесполезен без изменений на стороне
единственного реального потребителя. В
[`dialogue_audio_player.dart`](lib/widgets/dialogue_audio_player.dart):

- каждый путь, полученный из `ensureAudio()` внутри `_start()`'s
  prepare-цикла, немедленно добавляется в локальный `preparedPins`
  СИНХРОННО в тот же момент, до какой-либо проверки `mounted`/`token` —
  если операция окажется устаревшей на этом же шаге (виджет
  disposed/superseded), её собственный `preparedPins` release'ится тут
  же, а не остаётся висеть до случайного momента;
- как только весь список подготовлен и передан в `_paths`, эти пути
  считаются «на руках» у виджета до одной из точек освобождения:
  нормальное завершение диалога (`_playFrom` доходит до
  `index >= paths.length`), ошибка синтеза (catch в `_start()`), ошибка
  воспроизведения (`_playFrom`'s catch, теперь дополнительно делает
  best-effort `_player.stop()` — сбой `setPlaybackRate()` после
  успешного `play()` иначе оставил бы реально играющее аудио без
  контроля под error UI), `stop()`, `regenerate()` (release **до**
  `clearCache`, а не после — иначе `TtsService`'s pin-бухгалтерия
  осталась бы рассинхронизирована с файлами, которые `clearCache` уже
  удалил напрямую), `dispose()` и устаревшая (`stale`) операция,
  заметившая расхождение `token`/`_opToken` на своём собственном шаге;
- `_togglePause()`'s `pause()`/`resume()` catch-обработчики раньше
  просто переводили в error state, оставляя реальное воспроизведение
  играть в фоне без надзора — теперь общий `_failActive()` хелпер
  делает best-effort `stop()` и release lease при ЛЮБОЙ из этих ошибок,
  как и `_cycleSpeed()`'s `setPlaybackRate` failure;
- `dispose()`: `_player.dispose()` (тип `Future<void>`) раньше вызывался
  без `await`/обработки — сбой этого Future становился необработанным
  async exception. Теперь `unawaited(_player.dispose().catchError((_) {}))`
  (State.dispose() не может быть `async`, поэтому это осознанно
  fire-and-forget, но ошибка гарантированно поглощается). Release lease
  на текущий `_paths` тоже fire-and-forget по той же причине, но вызван
  ДО disposal плеера, а инвалидация `_opToken` — самой первой строкой
  метода (устаревшее продолжение не должно ничего воспроизвести).

**Дополнительно найденный и исправленный смежный баг: race двух `_playFrom`
с ОДНИМ `_opToken`.** `_jumpTo()` (тап по реплике в транскрипте) не
увеличивает `_opToken` — два быстрых тапа по разным репликам делят один
и тот же `token`. Существовавшая защита `token != _opToken` этого не
ловит, поэтому более старый (по факту вызова) `_playFrom`, чей
`play()` завис дольше, мог зарегистрировать completion-listener ПОСЛЕ
того, как более новый уже зарегистрировал свой — оба остаются активными
подписчиками на broadcast `onPlayerComplete`-стрим (переприсваивание
`_onCompleteSub` не отменяет предыдущую подписку), и при завершении
клипа сработали бы ОБА, из которых один — устаревший — заново
воспроизвёл бы уже пройденную реплику. Добавлен независимый счётчик
`_playSeq`, инкрементируемый в начале каждого `_playFrom` (в отличие от
`_opToken`, который относится к целой операции, `_playSeq` — к
конкретному вызову); каждая точка после `await` в `_playFrom` и внутри
самого completion-listener теперь дополнительно сверяет захваченный
`seq` с текущим `_playSeq`.

**Обязательные тесты TTS** (`test/services/tts_cache_test.dart`,
группа `concurrent LRU eviction across different keys` переписана на
три теста):

1. два конкурентных commit'а разных ключей (600Б+600Б, лимит 1000Б):
   оба Future в момент резолва указывают на существующий файл (ключевой
   регрессионный тест — раньше здесь стояло `existsA != existsB`, что
   ПРОТИВОРЕЧИТ гарантии), `.tmp` отсутствует, оба файла ещё физически
   присутствуют, пока никто не release'ил (никакого over-eviction, пока
   lease держится);
2. после `releasePaths()` обоих путей: возвращаемый Future дожидается
   отложенного eviction-прохода, итоговый размер ≤ лимита, ровно один
   файл выживает (не ноль — over-eviction, не два — broken budget),
   `.tmp` отсутствует, повторный запрос эвиктнутого ключа ресинтезирует
   его заново (ровно 1 новый HTTP-вызов);
3. три конкурентных ключа (лимит 1400Б): все три пути существуют, пока
   держится lease; после `releasePaths()` всех трёх остаётся
   математически верное число LRU-survivor'ов (2), `.tmp` отсутствует.

Плюс обновлены два существовавших single-key eviction-теста (`eviction
removes the least-recently-used clip first...`, `replaying a cached
clip touches its mtime...`) — они больше не просто вызывают
`ensureAudio()` и ожидают немедленной эвикции: каждый явно освобождает
lease через `releasePaths()` после «использования» клипа, прежде чем
следующая запись должна его вытеснить (без этого правки в pin-модели
оставили бы оба клипа запиненными навечно внутри одного теста и сломали
бы прежнюю проверку). Existing same-key/`forceRegenerate`/failure-recovery/
legacy-cleanup тесты не менялись и продолжают проходить без модификаций.

**Обязательные тесты DialogueAudioPlayer**
(`test/widgets/dialogue_audio_player_test.dart`, новая группа
`lease release`, плюс точечные добавления в существующие тесты):

- запрошенный проверкой тест с `_FakeAudioPlayerAdapter`, у которого
  `dispose()` бросает: после unmount `tester.takeException()` — `null`,
  нет setState-after-dispose, `TtsService.instance.debugPinCountsForTests`
  пуст (lease освобождён несмотря на сбой adapter'а);
- release при нормальном завершении диалога (единственная реплика,
  `fireComplete()` → идёт в natural-end branch → lease пуст);
- release при `stop()`;
- release при синтезационной ошибке в середине многострочного диалога
  (первая реплика успешно синтезирована и запинена, вторая падает 500 —
  lease первой обязан быть освобождён, а не остаться висеть);
- release при `regenerate()` — тест на РЕФКАУНТ, не просто на
  «что-то пусто»: `forceRegenerate` пересинтезирует тот же самый cache
  key (тот же путь), поэтому если release старого lease не произошёл ДО
  повторного пина нового, счётчик оказался бы 2, а не 1 — тест это явно
  проверяет через `debugPinCountsForTests.values == [1]`;
- release при устаревшей (stale) операции — уже существовавшие
  dispose-mid-prepare и mount-fresh-after-dispose тесты дополнены
  проверкой `debugPinCountsForTests` в конце: пусто;
- регрессия на `_playSeq`: три реплики, один тап (turnOne) искусственно
  «завешен» через новый `gateNextPlay` seam (гейтит именно СЛЕДУЮЩИЙ
  вызов `play()`, а не обязательно первый — иначе воспроизвести именно
  этот порядок разрешения без искусственной задержки было бы
  недетерминированно), второй тап (turnTwo) разрешается сразу и
  становится «текущим». Ключевая проверка — не через фактическое
  срабатывание обоих completion-listener'ов (в `flutter_test`'s
  `runAsync` доставка broadcast-события подписке, созданной в БОЛЕE
  РАННЕМ `runAsync`-заходе, ненадёжно наблюдаема — особенность тестового
  харнесса, а не реального `audioplayers`-поведения; отдельно
  подтверждено independent standalone-скриптом вне `flutter_test`, что
  сам Dart `StreamController.broadcast()` доставляет обоим подписчикам
  нормально), а через прямой счётчик `completeListenCount` на
  `_FakeAudioPlayerAdapter`: устаревший (turnOne) вызов, доразрешившись
  ПОСЛЕ того как новый (turnTwo) уже подписался, обязан НЕ дойти до
  повторной подписки — счётчик обязан остаться 2 (а не вырасти до 3).
  Проверено как настоящий regression: временный откат `_playSeq`-проверок
  воспроизводит `completeListenCount == 3`;
- `setPlaybackRate()`-failure и `play()`-failure тесты (уже существовали
  из второго раунда) дополнены проверкой `stopCallCount >= 1`
  (best-effort stop теперь реально вызывается) и
  `debugPinCountsForTests` пуст.

**Доказательство регрессионности.** Каждый из трёх новых/переписанных
блоков (cross-key eviction pin, `_playSeq`) был явно проверен методом
временного отката: `_pinnedPaths`-проверка в `_enforceCacheBudget`
удалялась → соответствующие TtsService-тесты стабильно падали на
`existsA=true, existsB=false`-подобном несоответствии; `|| seq !=
_playSeq` удалялось из всех проверок в `_playFrom` → тест на rapid jumps
стабильно падал на `completeListenCount == 3` вместо `2`. После
восстановления исправлений — стабильно зелёные повторные прогоны.

**Полный gate после исправлений:** `dart format --output=none
--set-exit-if-changed .` чист; `flutter analyze` — `No issues found!`;
`flutter test` — 261/261 (было 255, +6: `tts_cache_test.dart` группа
`concurrent LRU eviction across different keys` 2→3 (+1) и два
single-key eviction-теста дополнены release-вызовами без изменения
количества; `dialogue_audio_player_test.dart` +5 новых тестов в группе
`lease release`); `flutter test --coverage` — 2510/4786 строк (52,44%,
было 51,05%); backend не менялся в этой сессии (0 diff кодом),
незакоммиченный `.idea/` в backend-репозитории не тронут; `git diff
--check` чист. Device integration smoke **выполнен**: телефон Samsung
SM-S938B (`RFCY51N8PEK`) подключён,
`tool/run_android_integration.sh RFCY51N8PEK` прошёл 1/1
(`pdf_course_smoke_test.dart`); после теста подтверждены `pm path
com.linguaproapps.exam_trainer` (production package на месте,
`versionCode=10`, `versionName=1.0.0`) и отсутствие
`com.linguaproapps.exam_trainer.integration`. Как и в предыдущих
раундах, этот smoke общий (PDF→курс→упражнение), не TTS/audio-специфичный
— pin/lease и `_playSeq`-логика по-прежнему покрыты только host-side
unit/widget-тестами с fake HTTP client и fake audio adapter, не
интеграционным тестом на реальном устройстве.

Ни backend API, ни production endpoint, ни формат `ParsedCourse`, ни
ключи/формат TTS-кэша, ни публичная сигнатура `ensureAudio` (возвращает
`Future<String>`, как и раньше), ни Free/Premium-ограничения, ни
UID-изоляция, ни Firebase Auth не менялись. `TtsService` получил один
новый публичный метод — `releasePaths(Iterable<String>)`; единственный
существующий вызывающий (`DialogueAudioPlayer`) обновлён вызывать его на
каждой из перечисленных выше точек освобождения.

**Честный статус CR-14 после этого (третьего) раунда: закрыт с
доказанной гарантией возвращаемого пути.** Ключевое отличие от
предыдущего (ошибочного) заявления «закрыт» во втором раунде: на этот
раз гарантия «`ensureAudio()` никогда не резолвится уже удалённым путём»
доказана и для сценария, где протокол защиты — не «эксклюзия одного
прохода», а «глобальный, разделяемый между всеми операциями pin» —
и это тестами воспроизведено именно как временной race (реальные
задержки в mock HTTP client, `Future.wait` на нескольких параллельных
`ensureAudio()`), а не как последовательный вызов. Остаточные риски:
(1) как и в предыдущих раундах, вся эта синхронизация проверена только
host-side с фейковыми зависимостями — ни pin/lease-гонка, ни
`_playSeq`-race не имеют выделенного device/integration-теста с реальным
`audioplayers` и реальной файловой системой под нагрузкой; (2) если
когда-нибудь появится ВТОРОЙ реальный потребитель `TtsService.ensureAudio`
(не только `DialogueAudioPlayer`), он ОБЯЗАН освобождать свои pin через
`releasePaths()` самостоятельно — на уровне типов это не гарантируется
(в отличие от предыдущего явного `exclude`-параметра, эта модель
полагается на дисциплину каждого конкретного вызывающего, а не на
сигнатуру функции); задокументировано в docstring `ensureAudio()` и
`releasePaths()`, но не enforced компилятором. CR-13/CR-15/CR-16 не
изменились в этом раунде — тот же задокументированный частичный статус.

Реализация этого раунда сохранена Flutter-коммитом `a970ca0`
(branch `phase5-account-deletion`) — фактический hash записан отдельным
follow-up docs-коммитом, см. `NEXT_AGENT_PROMPT.md`.

### Четвёртый раунд независимой перепроверки P2 (CR-14): ownership-safe lease и clearCache — 16 июля 2026

Проверка реализации `a970ca0` нашла ещё два детерминированных дефекта в
контракте явного release, поэтому статус «закрыт» из третьего раунда снова
был преждевременным:

1. `releasePaths(Iterable<String>)` идентифицировал владельца только строкой
   пути. Если два потребителя держали один и тот же cache key, повторный
   release первого потребителя уменьшал общий refcount второй раз и снимал
   защиту второго владельца. Идемпотентность существовала для пути с нулевым
   refcount, но не для конкретного владения.
2. `clearCache()` удалял файл без учёта `_pinnedPaths`. После release lease
   текущего `DialogueAudioPlayer` regenerate мог удалить общий путь, который
   всё ещё использовал другой экземпляр плеера. Его refcount оставался в
   памяти, но физического файла уже не было.

Оба сценария воспроизведены до исправления: два `ensureAudio()` одной реплики
давали refcount 2; двойной release одного строкового пути ошибочно доводил его
до 0, а `release A → clearCache()` удалял файл при активном lease B.

**Исправление.** Публичный контракт `ensureAudio()` теперь возвращает
`TtsAudioLease`, а не неразличимый `String`. Каждое получение получает
уникальный внутренний id и собственный идемпотентный `release()`; повторный
release того же объекта возвращает тот же Future и не может затронуть другого
владельца. Путь доступен как `lease.path`. Единственный production caller,
`DialogueAudioPlayer`, переведён с `List<String>` на `List<TtsAudioLease>` и
освобождает именно принадлежащие ему объекты на прежних lifecycle-точках.
Таким образом требование release теперь enforced типом API, а прежний
остаточный риск «новый caller забудет сопоставить строковые refcount» устранён
частично: release всё ещё нужно вызвать, но невозможно случайно освободить
чужое владение повторным вызовом со своей стороны.

Все операции, меняющие состояние TTS-кэша, сведены в одну
`_cacheTransactionChain`: проверка/touch cache hit и создание lease,
атомарный commit+eviction, отложенная eviction после release и `clearCache`.
Сетевой синтез разных ключей остаётся параллельным. `clearCache()` внутри этой
очереди пропускает любой путь, который всё ещё держит хотя бы один владелец;
после release последнего lease повторная очистка удаляет файл. Снятие
ownership/refcount выполняется синхронно до постановки eviction в очередь,
чтобы синхронные UI lifecycle-методы `stop()`/`dispose()` немедленно
переставали удерживать lease; файловые действия при этом остаются
сериализованными.

**Тесты.** Весь `tts_cache_test.dart` мигрирован на типизированный lease API;
добавлены две отдельные регрессии в группе `ownership-aware leases`:

- два владельца одного пути, двойной `first.release()` оставляет refcount 1 и
  существующий файл второго владельца;
- `clearCache()` сохраняет путь при активном lease второго владельца и
  удаляет его только после `second.release()`.

Фокусный gate `tts_cache_test.dart + dialogue_audio_player_test.dart` — 35/35;
полный `flutter analyze` чист, `flutter test` — 263/263,
`flutter test --coverage` — 2521/4799 строк (52,53%); `dart format
--output=none --set-exit-if-changed .` и `git diff --check` чисты. Backend
72/72 + `py_compile` прошёл во временном venv вне репозитория (backend-код
не менялся). `flutter build apk --release` успешно собрал production APK;
Gradle вывел только известное предупреждение CR-16 о будущей миграции
`device_info_plus`/`file_picker` с Kotlin Gradle Plugin. Device smoke на
Samsung SM-S938B (`RFCY51N8PEK`) прошёл 1/1 через безопасный
`tool/run_android_integration.sh`; production package остался установлен
(`versionCode=10`, `versionName=1.0.0`), integration package удалён.
Backend API, production endpoint, TTS cache key/file format, ParsedCourse,
Free/Premium, UID-изоляция и Firebase Auth не менялись. CodeGraph/literal
search подтвердили, что других production callers `ensureAudio()` нет.

**Статус CR-14 после четвёртого раунда: закрыт на уровне проверенных
ownership/cache races.** Остаточный риск — host-side fake filesystem/player
не заменяет нагрузочный тест реального `audioplayers` на устройстве; кроме
того, любой новый caller по-прежнему обязан вызвать `lease.release()`, хотя
теперь ownership и идемпотентность enforced отдельным объектом.

Реализация и Flutter-документация этого раунда сохранены коммитом
`4d1c668` в ветке `phase5-account-deletion`; backend-код не менялся,
канонический `PRODUCT_PLAN.md` обновлён docs-коммитом `d89e8cf` в ветке
`phase3-2-promptfoo-gate`.

### Продолжение P2 (CR-15): идентификация пропусков и масштаб текста 200% — 16 июля 2026

Отложенный разрыв в двух Sprachbausteine-экранах подтверждён по реальному
коду: стандартный `DropdownButton` сообщал выбранное значение и действие, но
не номер пропуска. В Teil 1 внутренний `gapIndex` дополнительно терял
оригинальный номер PDF-маркера, поэтому простое `gapIndex + 1` озвучило бы
неверные номера вместо, например, `[52]`/`[53]`.

**Исправление.** `_Part` Teil 1 теперь сохраняет и внутренний индекс выбора,
и исходный `questionNumber`; Teil 2 использует уже типизированный
`ExerciseQuestion.number`. Оба dropdown обёрнуты в отдельный `Semantics`
container с локализованным `S.lueckeAuswaehlen(number)` для de/ru/uk/en.
Вложенная семантика не исключается: TalkBack по-прежнему получает tap action
и текущее значение Dropdown. Минимальная высота цели — 48 dp.

Первый 200%-тест воспроизвёл два реальных layout-дефекта до исправления:
Teil 1 overflow на 69 px и Teil 2 на 27 px. Выбранный inline-элемент теперь
имеет scale-aware ограниченную ширину и ellipsis, а меню получает отдельную
ширину до 320 dp, поэтому полный вариант остаётся доступен при раскрытии.
`RichText` заменён на `Text.rich`, чтобы inline-текст наследовал актуальный
`TextScaler`.

**Тесты и устройство.** Добавлено 6 host widget tests
`sprachbausteine_gap_accessibility_test.dart`: четыре locale, реальные
неединичные номера `[52]`/`[53]`, сохранённый `SemanticsAction.tap`, значение
после выбора, 48 dp и русский UI при `TextScaler.linear(2.0)` на viewport
412×915 без overflow. Новый backend-free device test
`sprachbausteine_accessibility_smoke_test.dart` выполняет оба экрана и выбор
ответа через isolated integration flavor. Безопасный runner теперь запускает
два smoke: PDF flow 1/1 и CR-15 1/1 на Samsung SM-S938B; integration package
удалён. Production package отсутствовал на телефоне ещё до этого прогона,
поэтому его сохранность именно в этом запуске подтвердить было невозможно,
хотя fail-safe guard runner сохранён.

Полный gate: format/analyze чисты; `flutter test` и coverage — 269/269,
2829/4822 строк (58,67%); release APK 59,2 MB собран; `git diff --check` и
`bash -n tool/run_android_integration.sh` чисты. Backend не менялся.

**Статус CR-15:** отслеживаемая кодовая часть (gap labels, действия/значения,
48 dp и точный 200%-layout на host + Android) выполнена. Статус всего
рекомендованного accessibility-аудита остаётся частичным до ручного прогона
TalkBack: автоматизация проверяет дерево Semantics и действия, но агент не
может честно подтвердить фактически произнесённый текст, порядок речевого
фокуса, high contrast и keyboard navigation. Настройки телефона через ADB не
менялись.

Реализация, тесты и Flutter-документация сохранены коммитом `3bb1ec3` в ветке
`phase5-account-deletion`; канонический backend-план обновлён docs-коммитом
`e763c08` в ветке `phase3-2-promptfoo-gate`, backend-код не менялся.

### Исправление зависания startup overlay на новой установке — 16 июля 2026

На втором устройстве Samsung SM-G985F воспроизведено бесконечное состояние
«Prüfungstrainer wird vorbereitet …» после новой установки. Android/Flutter
процесс оставался жив, первый Flutter frame был отрисован, исключений не было.
Причина подтверждена в `app.dart`: внешний `MaterialApp.router.builder` читал
исходный `routeInformationProvider` (`/`), тогда как GoRouter уже завершил
внутренний redirect неавторизованного пользователя на `/login`. Builder не
обязан перестраиваться от изменения вложенного Router, поэтому login был
отрисован под overlay, который никогда не получал сигнал готовности.

Добавлен `RouterStartupOverlay`: он слушает `routerDelegate` и читает
`currentConfiguration`, то есть фактически разрешённый маршрут. Для пустой
начальной конфигурации overlay остаётся; для любого готового маршрута кроме
Home снимается после frame; Home сохраняет прежнюю отдельную готовность после
загрузки локальной библиотеки. Redirect сделан синхронным, поскольку внутри
него нет асинхронной работы.

Регрессионный widget test использует настоящий GoRouter и управляемый
асинхронный redirect `/` → `/login`: до завершения redirect overlay виден,
после него виден Login и overlay отсутствует. Полный gate: format/analyze
чисты, `flutter test` — 271/271, coverage — 2849/4841 (58,85%),
`git diff --check` чист. Production release APK собран и дважды холодно
запущен на том же SM-G985F: оба запуска завершились экраном Login без
Flutter/Android crash. APK: 59 513 582 bytes, SHA-256
`f19718cb60597e1a707bbddbad8f281313c6c940170a55ad16ddef490674b460`.

После integration/coverage Flutter может оставить игнорируемый Java
registrant с dev-only `IntegrationTestPlugin`; чистый release не содержит эту
dev-зависимость и закономерно не компилирует такой stale-файл. Для
воспроизводимой сборки добавлен `tool/build_android_release.sh`: он удаляет
только этот игнорируемый генерируемый registrant при наличии dev-plugin и
запускает обычный `flutter build apk --release`. Signing/API/Firebase и
production package id скрипт не меняет.

Safe Android integration runner на SM-G985F прошёл оба isolated smoke:
PDF → course → exercise → reload — 1/1, Sprachbausteine accessibility при
200% — 1/1. Integration package после теста удалён, production package
сохранён. Финальный APK повторно установлен и холодно запущен: виден Login,
startup overlay отсутствует, FATAL/Unhandled Exception в logcat нет.

### Исправление выбора пола TTS для Andrea — 16 июля 2026

> Исторический промежуточный фикс. Заменён общим решением в следующем
> разделе; списки конкретных имён на backend больше не используются.

На реальном Hören Teil 4 подтверждён мужской голос для монолога «Hallo, hier
ist Andrea Faber». Клиент распознавал рассказчика только по `Herr/Frau`,
поэтому отправлял `/api/tts` пустой `speaker`; backend для пустого значения
детерминированно выбирал из объединённого мужского и женского пула.

`TtsService._detectNarrator` теперь поддерживает самопредставления `hier
ist/spricht`, `ich bin` и `mein Name ist`, сохраняя проверку заглавной буквы
имени против ложных совпадений. Для проблемного текста speaker становится
`Andrea Faber`; это также создаёт новый cache key и не переиспользует старый
мужской MP3. Backend добавил `andrea` в женский набор `_gender`; контракт и
формат `/api/tts` не менялись.

Добавлены три Flutter regression tests: распознавание Andrea, защита от
lowercase false positive и раздельный cache key; backend test гарантирует,
что `voice_for("Andrea Faber")` возвращает только `FEMALE_VOICES`. Gate:
Flutter 274/274, coverage 2851/4843 (58,87%), analyze/format чисты; backend
73/73 + `py_compile`; `git diff --check` чист. После полного clean production
APK собран с SHA-256
`16bcb436ec325cf231d7ff6f3f00a61dcc13e8282be04651bd8710d129968e78` и
установлен на SM-G985F; cold launch без crash. На этом устройстве нет
авторизованного курса с Andrea, поэтому фактическое звучание нужно повторно
прослушать на телефоне пользователя после установки сборки.

Дополнительно release wrapper теперь всегда выполняет `flutter clean` и
`flutter pub get`: incremental build дважды оставил прежний APK/hash после
изменения Dart, поэтому release-артефакт больше не полагается на старый
Flutter/Gradle snapshot.

### Robust TTS gender rollout — 16 июля 2026

Реализован staged compatible контракт пола TTS вместо одноразовой связки
Flutter→Andrea. Backend `/api/tts` принимает optional
`voice_gender: female|male|unknown`; отсутствие поля и `unknown` сохраняют
совместимое поведение для старых клиентов, а `female`/`male` переопределяют
эвристики явных ролей (`Frau`/`Herr`). Списки конкретных имён удалены: новые
имена обрабатываются динамической parser metadata, сомнительные случаи
остаются `unknown`, а пользователь может выбрать голос вручную.

Parser/schema получили optional `metadata.voice_gender` для монологов и
`metadata.speaker_voice_genders[]` для диалогов. Span resolution сохраняет
валидную metadata и отбрасывает malformed hints без поломки старого course
JSON. Flutter читает nested `metadata`, defensively парсит `VoiceGender`,
использует приоритет manual override → parsed hint/per-speaker hint →
explicit `Frau`/`Herr` → `unknown`, отправляет `voice_gender` только для
известного пола и использует v2 gender-aware cache key, чтобы старый MP3 не
переиспользовался после исправленного выбора.

Добавлен UID-isolated `VoicePreferenceRepository` на SharedPreferences с
serialized latest-wins writes и cleanup при удалении аккаунта. Signed-out
режим ничего не пишет в общий `anonymous` namespace. Recording IDs включают
course ID, позицию edition/pair/text и hash при потере non-ASCII символов,
поэтому одинаковые, пустые и кириллические labels не пересекаются.
`DialogueAudioPlayer` получил localized
Automatic/Female/Male controls, per-speaker controls for dialogues,
`didUpdateWidget` reset, stale-operation rejection, stop+lease release and no
autoplay on text/recording/metadata/override switch.

Покрытие добавлено для old courses, invalid metadata, endpoint validation,
span preservation, gender-aware cache separation, UID isolation/account
deletion, rapid writes, async switching/dispose, Telefonnotiz version switch,
localization/Semantics и multi-speaker behavior. Gate: `dart format
--output=none --set-exit-if-changed .` clean, `flutter analyze` clean,
`flutter test` 299/299, `flutter test --coverage` 3207/5229 (61.33%),
Flutter/backend `git diff --check` clean, backend `py_compile` clean и полный
backend gate 86/86. Parse cache поднят `v36` → `v37`, чтобы сохранённые
pre-metadata результаты не обходили новый контракт. На Samsung SM-G985F safe
PDF integration прошёл, production release APK собран и установлен; cold
launch успешен, crash/exception в logcat нет. APK SHA-256:
`eb71a83f38b9f8f5ee1531ab4ee4c42192341ac407276dad7a5c5a2bc91adf7f`.
Телефон находится на Login, поэтому фактический Edge TTS для Andrea и других
записей остаётся прослушать после входа в авторизованный тестовый курс.

### Hören Teil 4: упомянутый человек не является рассказчиком — 16 июля 2026

Реальный device-test выявил независимый клиентский дефект: монолог №40
правильно содержит рассказчицу Bernhardt и упоминает её секретаря Frau Zimmer,
но `TtsService._detectNarrator()` искал первое `Herr/Frau` во всём тексте.
Из-за этого UI подписывал весь монолог как `Frau Zimmer`. Распознавание
gendered narrator теперь ограничено настоящими self-introduction в начале
текста (`hier ist/spricht`, `ich bin`, `mein Name ist`, `am Apparat`), поэтому
упомянутые третьи лица больше не становятся speaker label. Конкретные имена не
захардкожены; parsed `voice_gender` продолжает определять голос.

Regression test воспроизводит точную фразу `meiner Sekretärin Frau Zimmer` и
проверяет: speaker остаётся пустым, parsed female metadata сохраняется. Gate:
format чист, `flutter analyze` без замечаний, targeted 18/18 и полный
`flutter test` 300/300. Актуальный production curated v37 независимо проверен:
№38 Daniela Schöller — female, №39 Guido Lattermann — male, №40 Bernhardt —
female. Старые локальные курсы не обновляются автоматически: для проверки
пользователю нужно удалить курс, импортировать PDF заново, оставить voice
control в `Auto` и при необходимости очистить Android cache старых MP3.

### Сворачивание транскрипта не останавливает аудио — 16 июля 2026

Device UX-проверка выявила, что в universal Hören Teil 2–4 сворачивание
карточки удаляло `DialogueAudioPlayer` из widget tree. Его `dispose()` штатно
останавливал player и освобождал leases, поэтому пользователь не мог слушать
запись, одновременно просматривая вопросы. Карточка теперь скрывает detail
через state-preserving `Visibility`: плеер остаётся смонтированным и продолжает
воспроизведение, скрытая область не занимает место, вопросы остаются доступны.
Hören Teil 1 и Telefonnotiz не были затронуты — там player из дерева не
удалялся.

Widget regression test раскрывает Hören Teil 4, запоминает State плеера,
сворачивает карточку и проверяет тот же State через `skipOffstage: false`,
отсутствие видимого divider и доступность вопроса ниже.

### Account session actions follow-up — 17 июля 2026

Исторический review и предыдущий handoff требовали проверить сценарий
`sign-out/in другим UID`, но отдельной logout-кнопки в профиле ранее не было.
Текущий рабочий diff добавляет локализованное действие **Abmelden / Sign out**
рядом с удалением аккаунта и покрывает его callback-тестом во всех четырёх
поддерживаемых локалях. Реализация вызывает `AuthService.signOut()`, после
успеха направляет пользователя на `/login`, а при сбое оставляет конечное
состояние с локализованным сообщением вместо сырого исключения.

Отдельного режима «сменить аккаунт» с выбором сохранённых аккаунтов по-прежнему
нет. Безопасный сценарий смены UID — logout → обычный Login → вход другим
Firebase UID; общий anonymous namespace и cross-UID данные не создаются.
Приёмка: успешный logout открывает Login; ошибка logout не навигирует неожиданно;
другой UID не видит курсы, favorites и voice preferences прежнего UID;
account-deletion cleanup/outbox guarantees не регрессировали; widget/integration
tests покрывают logout, delete confirmation и UID switch.

До отдельного review и полного Flutter/device gate этот working-tree diff не
считается опубликованным release-коммитом. Не staging-ить пользовательские
изменения без согласования; отдельный switch-account UI остаётся следующей
задачей только если продукту нужен выбор нескольких активных сессий.

### Account sheet device verification — 17 июля 2026

На Samsung SM-G985F исходный account bottom sheet обрезал нижние действия:
legal-ссылки были видны, а logout/delete находились ниже viewport. Sheet
переведён в `isScrollControlled` с `SafeArea` и `SingleChildScrollView`.
После установки production APK оба действия стали видимыми на экране 720×1461;
нажатие `Abmelden` на авторизованном аккаунте фактически перевело приложение
на Login. Полный integration runner в этом раунде не засчитан из-за обрыва
Wi-Fi ADB во время teardown; ручная logout-проверка прошла.

### Sprachbausteine Teil 1 visual follow-up — 17 июля 2026

Пользовательский скриншот, названный Beschwerde, фактически относится к
`Sprachbausteine Teil 1`: это inline-пропуски `DAMIT`, `SICHER`, `SONDERN`,
`ÜBER`. В `BeschwerdeExerciseScreen` dropdown-ов нет, поэтому его код не
менялся. Для Sprachbausteine inline-select стал компактнее: выбранный элемент
получил ограниченную ширину, лёгкую рамку и явную стрелку; меню вариантов
сохраняет широкую область для чтения длинных слов. Исходный PDF question number,
gapIndex, single-use selection и scoring не менялись.

Добавлен regression-тест на 360×800 при text scale 200% с длинным выбранным
вариантом: layout exceptions отсутствуют, tap Semantics сохраняется, полное
слово доступно в Semantics value. Фактический TalkBack spoken order и ручная
визуальная оценка на устройстве остаются отдельными пунктами проверки.

Ручная визуальная проверка baseline-варианта на телефоне завершена 18 июля:
пользователь подтвердил, что короткие пропуски остаются внутри строки и больше
не разрывают предложение. Изменение `WidgetSpan` на alphabetic baseline и
удаление принудительного центрирования принято; функциональность выбора,
scoring и Semantics не менялась.

### Lesen Teil 4: визуальное разделение протокола — 18 июля 2026

Проверен экран `Lesen Teil 4 · Zulieferer, Fahrtenbuch`. Flattened-контент
действительно приходит одной строкой, хотя исходный PDF содержит отдельные
метаданные и абзацы TOP; проблема подтверждена как клиентское форматирование,
а не ошибка backend API.

В `UniversalExerciseScreen` форматирование ограничено `sectionType ==
'lesen_teil4'`: подписи протокола получают отдельные строки и визуальный
акцент, а TOP 1/2/3 — отдельные абзацы и жирное teal-оформление. Hören и
остальные universal-секции не затрагиваются. Добавлены unit/widget regression
тесты для flattened-протокола, markdown/TOP, non-Lesen compatibility и 200%
text scale без layout exceptions. Targeted suite: 24/24 зелёных; полный gate и
device smoke выполняются перед публикацией.

### CR-13/CR-16 follow-up — 18 июля 2026

CR-13 получил минимальный безопасный срез для `FavoritesScreen`: прямой
`FutureBuilder` заменён на инъецируемый `FavoritesController` с конечными
состояниями loading/content/empty/error, retry и защитой от устаревших
операций/dispose. Ошибка `FavoritesService.getAll()` больше не оставляет
вечный spinner. Добавлены controller и widget regression-тесты.

По CR-16 обновлён только `device_info_plus` `10.1.2 → 12.4.0` (и совместимый
`win32_registry`). Изолированная копия подтвердила analyze, полный test и debug
APK build; production caller использует только стабильные `brand/model/name`.
`13.2.0` пока не берётся: текущий `file_picker 10.3.10` конфликтует с его
`win32`-требованием. Предупреждение старого KGP от `file_picker` остаётся
отдельным риском.

Device gate после обновления выполнен на Samsung SM-G985F по Wi-Fi ADB:
PDF flow 1/1 и Sprachbausteine accessibility 1/1, production package
`versionCode=10` сохранён, integration package удалён. Свежий production APK
установлен поверх существующего через `adb install -r`. Ручной TalkBack,
high-contrast и keyboard audit остаются отдельной пользовательской проверкой;
accessibility-настройки телефона через ADB не менялись.
