import 'package:flutter/material.dart';

/// Simple in-code localization for de / ru / uk / en — same pattern as the
/// sister deutch-lernen app's lib/l10n/strings.dart, for consistency.
///
/// Only the app's OWN UI chrome is translated here. Exam content parsed
/// from an imported PDF (dialogues, questions, letters — actual German
/// exam material) always stays in German regardless of UI language, same
/// as it would on the real exam paper.
///
/// Usage:
///   final s = S.of(context);
///   Text(s.importPdf)
class S {
  static S of(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return S._(lang);
  }

  final String _lang;
  const S._(this._lang);

  String _t(String de, String ru, String uk, [String? en]) {
    if (_lang == 'en') return en ?? de;
    if (_lang == 'uk') return uk;
    if (_lang == 'ru') return ru;
    return de;
  }

  // ── Home ──────────────────────────────────────────────────────────────
  String get willkommen =>
      _t('Willkommen', 'Добро пожаловать', 'Ласкаво просимо', 'Welcome');
  String get uebungsbereiche => _t(
    'Übungsbereiche',
    'Разделы упражнений',
    'Розділи вправ',
    'Practice sections',
  );
  String get muendlichePruefung =>
      _t('Mündliche Prüfung', 'Устный экзамен', 'Усний іспит', 'Oral exam');
  String get eigenesPdf => _t('EIGENES PDF', 'СВОЙ PDF', 'СВІЙ PDF', 'OWN PDF');
  String get pruefungMitEigenemMaterial => _t(
    'Prüfung mit\neigenem Material üben',
    'Готовьтесь к экзамену\nпо своим материалам',
    'Готуйтеся до іспиту\nза власними матеріалами',
    'Practice with\nyour own material',
  );
  String get pdfHochladenHint => _t(
    'Laden Sie ein PDF hoch — der Rest ist automatisch.',
    'Загрузите PDF — остальное сделает приложение.',
    'Завантажте PDF — решту зробить застосунок.',
    'Upload a PDF — everything else is automatic.',
  );
  String get pdfImportieren => _t(
    'PDF importieren',
    'Импортировать PDF',
    'Імпортувати PDF',
    'Import PDF',
  );
  String get pruefungWaehlen =>
      _t('Prüfung wählen', 'Выбор экзамена', 'Вибір іспиту', 'Choose Exam');
  String get niveauUndKursWaehlen => _t(
    'Niveau und Kursart wählen',
    'Выберите уровень и тип курса',
    'Виберіть рівень і тип курсу',
    'Choose level and course type',
  );
  String get meineKurse =>
      _t('Meine Kurse', 'Мои курсы', 'Мої курси', 'My courses');
  String get weiterlernen => _t(
    'Weiterlernen',
    'Продолжить обучение',
    'Продовжити навчання',
    'Continue learning',
  );
  String get kurse => _t('Kurse', 'Курсы', 'Курси', 'Courses');
  String get profil => _t('Profil', 'Профиль', 'Профіль', 'Profile');
  String get ausPdfImportiert => _t(
    'Aus PDF importiert',
    'Импортировано из PDF',
    'Імпортовано з PDF',
    'Imported from PDF',
  );
  String get keineKurseImportiert => _t(
    'Keine importierten Kurse',
    'Нет импортированных курсов',
    'Немає імпортованих курсів',
    'No imported courses',
  );
  String variantenCount(int n) =>
      _t('$n Varianten', '$n вариантов', '$n варіантів', '$n variants');
  String get syncPending => _t(
    'Wird synchronisiert …',
    'Ожидает синхронизации…',
    'Очікує синхронізації…',
    'Waiting to sync…',
  );
  String get syncSyncing => _t(
    'Synchronisierung läuft …',
    'Синхронизация…',
    'Синхронізація…',
    'Syncing…',
  );
  String get syncError => _t(
    'Cloud-Sicherung ausstehend',
    'Облачное сохранение не удалось, повторяем',
    'Хмарне збереження не вдалося, повторюємо',
    'Cloud backup pending retry',
  );
  String get syncRetryAction => _t(
    'Jetzt erneut versuchen',
    'Повторить сейчас',
    'Повторити зараз',
    'Retry now',
  );
  String get abmelden => _t('Abmelden', 'Выйти', 'Вийти', 'Sign out');
  String get kursLoeschenTitel =>
      _t('Kurs löschen?', 'Удалить курс?', 'Видалити курс?', 'Delete course?');
  String get abbrechen => _t('Abbrechen', 'Отмена', 'Скасувати', 'Cancel');
  String get loeschen => _t('Löschen', 'Удалить', 'Видалити', 'Delete');
  String get premiumKonto => _t(
    'Premium-Konto',
    'Премиум-аккаунт',
    'Преміум-акаунт',
    'Premium account',
  );
  String get kostenlosesKonto => _t(
    'Kostenloses Konto (1 Variante pro Bereich)',
    'Бесплатный аккаунт (1 вариант на раздел)',
    'Безкоштовний акаунт (1 варіант на розділ)',
    'Free account (1 variant per section)',
  );
  String get kontoLoeschen => _t(
    'Konto löschen',
    'Удалить аккаунт',
    'Видалити акаунт',
    'Delete account',
  );
  String get kontoLoeschenTitel => _t(
    'Konto endgültig löschen?',
    'Удалить аккаунт навсегда?',
    'Видалити акаунт назавжди?',
    'Permanently delete account?',
  );
  String get kontoLoeschenWarnung => _t(
    'Dies löscht dein Konto, alle importierten Kurse, deinen Fortschritt und '
        'alle registrierten Geräte unwiderruflich. Diese Aktion kann NICHT '
        'rückgängig gemacht werden.',
    'Это безвозвратно удалит ваш аккаунт, все импортированные курсы, '
        'прогресс и все зарегистрированные устройства. Это действие НЕЛЬЗЯ '
        'отменить.',
    'Це безповоротно видалить ваш акаунт, усі імпортовані курси, прогрес '
        'та всі зареєстровані пристрої. Цю дію НЕМОЖЛИВО скасувати.',
    'This will permanently delete your account, all imported courses, '
        'your progress and all registered devices. This action CANNOT be '
        'undone.',
  );
  String get kontoEndgueltigLoeschen => _t(
    'Endgültig löschen',
    'Удалить навсегда',
    'Видалити назавжди',
    'Delete permanently',
  );
  String get kontoWirdGeloescht => _t(
    'Konto wird gelöscht …',
    'Удаление аккаунта …',
    'Видалення акаунта …',
    'Deleting account …',
  );
  String get kontoLoeschenFehlerTitel => _t(
    'Löschen fehlgeschlagen',
    'Не удалось удалить',
    'Не вдалося видалити',
    'Deletion failed',
  );
  String get kontoLoeschenFehler => _t(
    'Dein Konto konnte nicht gelöscht werden. Bitte überprüfe deine '
        'Internetverbindung und versuche es erneut.',
    'Не удалось удалить аккаунт. Проверьте подключение к интернету и '
        'попробуйте снова.',
    'Не вдалося видалити акаунт. Перевірте підключення до інтернету та '
        'спробуйте ще раз.',
    'Your account could not be deleted. Please check your internet '
        'connection and try again.',
  );
  String get kontoLoeschenTeilfehlerTitel => _t(
    'Daten gelöscht, Konto noch aktiv',
    'Данные удалены, аккаунт ещё активен',
    'Дані видалено, акаунт ще активний',
    'Data deleted, account still active',
  );
  String get kontoLoeschenTeilfehler => _t(
    'Deine Daten wurden bereits gelöscht, aber das Konto selbst konnte '
        'nicht vollständig entfernt werden. Du wirst jetzt abgemeldet — bitte '
        'versuche es später erneut oder kontaktiere den Support unter '
        'linguaproapps@gmail.com.',
    'Ваши данные уже удалены, но сам аккаунт не удалось удалить '
        'полностью. Сейчас вы будете выйдены из аккаунта — попробуйте позже '
        'ещё раз или напишите в поддержку: linguaproapps@gmail.com.',
    'Ваші дані вже видалено, але сам акаунт не вдалося видалити повністю. '
        'Зараз вас буде вийдено з акаунта — спробуйте пізніше ще раз або '
        'напишіть у підтримку: linguaproapps@gmail.com.',
    'Your data has already been deleted, but the account itself could '
        'not be fully removed. You will now be signed out — please try again '
        'later or contact support at linguaproapps@gmail.com.',
  );

  // ── Device limit ───────────────────────────────────────────────────────
  String get deviceLimitTitel => _t(
    'Gerätelimit erreicht',
    'Лимит устройств достигнут',
    'Ліміт пристроїв досягнуто',
    'Device Limit Reached',
  );
  String get deviceLimitBody => _t(
    'Dein Konto ist bereits auf 2 Geräten aktiv.\n\n'
        'Du kannst dieses Gerät verwenden — alle anderen werden dabei abgemeldet.',
    'Ваш аккаунт уже активен на 2 устройствах.\n\n'
        'Вы можете использовать это устройство — все остальные будут отключены.',
    'Ваш акаунт вже активний на 2 пристроях.\n\n'
        'Ви можете використовувати цей пристрій — всі інші будуть відключені.',
    'Your account is already active on 2 devices.\n\n'
        'You can use this device — all other devices will be signed out.',
  );
  String get deviceLimitBenutzen => _t(
    'Dieses Gerät verwenden',
    'Использовать это устройство',
    'Використати цей пристрій',
    'Use This Device',
  );
  String get deviceLimitFehler => _t(
    'Das hat nicht geklappt. Bitte versuche es erneut.',
    'Не удалось выполнить действие. Попробуйте ещё раз.',
    'Не вдалося виконати дію. Спробуйте ще раз.',
    'That didn\'t work. Please try again.',
  );

  // ── Favorites ──────────────────────────────────────────────────────────
  String get favoriten => _t('Favoriten', 'Избранное', 'Обране', 'Favorites');
  String get lesezeichen =>
      _t('Lesezeichen', 'Избранное', 'Закладки', 'Bookmarks');
  String get gespeicherteUebungen => _t(
    'Gespeicherte Übungen',
    'Сохранённые упражнения',
    'Збережені вправи',
    'Saved exercises',
  );
  String get keineLesezeichen =>
      _t('Keine Lesezeichen', 'Нет закладок', 'Немає закладок', 'No bookmarks');
  String get lesezeichenHinweis => _t(
    'Tippe auf das Lesezeichen-Symbol bei einer Übung, um sie hier zu speichern.',
    'Нажмите на значок закладки в упражнении, чтобы сохранить его здесь.',
    'Натисніть на значок закладки у вправі, щоб зберегти її тут.',
    'Tap the bookmark icon on an exercise to save it here.',
  );
  String get lesezeichenGespeichert => _t(
    'Lesezeichen gespeichert',
    'Добавлено в закладки',
    'Додано до закладок',
    'Bookmark saved',
  );
  String get lesezeichenEntfernt => _t(
    'Lesezeichen entfernt',
    'Удалено из закладок',
    'Видалено із закладок',
    'Bookmark removed',
  );
  String get lesezeichenEntfernen => _t(
    'Lesezeichen entfernen',
    'Удалить закладку',
    'Видалити закладку',
    'Remove bookmark',
  );
  String get lesezeichenHinzufuegen => _t(
    'Lesezeichen hinzufügen',
    'Добавить закладку',
    'Додати закладку',
    'Add bookmark',
  );

  // ── Probeprüfung (mock exam) ──────────────────────────────────────────
  String get pruefungssimulation =>
      _t('Prüfungssimulation', 'Пробный экзамен', 'Пробний іспит', 'Mock Exam');
  String get neueAufgabenWaehlen => _t(
    'Neue Aufgaben wählen',
    'Выбрать новые задания',
    'Обрати нові завдання',
    'Pick new tasks',
  );
  String get pruefungStarten =>
      _t('Prüfung starten', 'Начать экзамен', 'Почати іспит', 'Start exam');
  String aufgabenMinuten(int tasks, int minutes) => _t(
    '$tasks Aufgaben · ca. $minutes Min.',
    '$tasks заданий · ок. $minutes мин.',
    '$tasks завдань · бл. $minutes хв.',
    '$tasks tasks · approx. $minutes min.',
  );
  String get probepruefungAbgeschlossen => _t(
    'Probeprüfung abgeschlossen!',
    'Пробный экзамен завершён!',
    'Пробний іспит завершено!',
    'Mock exam completed!',
  );
  String aufgabenErledigt(int done, int total, int pct) => _t(
    '$done von $total Aufgaben erledigt ($pct %)',
    '$done из $total заданий выполнено ($pct %)',
    '$done з $total завдань виконано ($pct %)',
    '$done of $total tasks completed ($pct%)',
  );

  // ── Language picker ─────────────────────────────────────────────────────
  String get sprache => _t('Sprache', 'Язык', 'Мова', 'Language');

  // ── Login ────────────────────────────────────────────────────────────────
  String get kontoErstellen => _t(
    'Konto erstellen',
    'Создайте аккаунт',
    'Створіть акаунт',
    'Create an account',
  );
  String get zumFortfahrenAnmelden => _t(
    'Zum Fortfahren anmelden',
    'Войдите, чтобы продолжить',
    'Увійдіть, щоб продовжити',
    'Sign in to continue',
  );
  String get mitGoogleAnmelden => _t(
    'Mit Google anmelden',
    'Войти через Google',
    'Увійти через Google',
    'Sign in with Google',
  );
  String get oder => _t('oder', 'или', 'або', 'or');
  String get passwort => _t('Passwort', 'Пароль', 'Пароль', 'Password');
  String get registrieren =>
      _t('Registrieren', 'Зарегистрироваться', 'Зареєструватися', 'Register');
  String get anmelden => _t('Anmelden', 'Войти', 'Увійти', 'Sign in');
  String get bereitsRegistriert => _t(
    'Bereits registriert? Anmelden',
    'Уже есть аккаунт? Войти',
    'Вже є акаунт? Увійти',
    'Already have an account? Sign in',
  );
  String get nochKeinKonto => _t(
    'Noch kein Konto? Registrieren',
    'Нет аккаунта? Зарегистрироваться',
    'Немає акаунта? Зареєструватися',
    'No account yet? Register',
  );
  String get ungueltigeEmail => _t(
    'Ungültige E-Mail.',
    'Некорректный email.',
    'Некоректний email.',
    'Invalid email.',
  );
  String get falscheAnmeldedaten => _t(
    'Falsche E-Mail oder falsches Passwort.',
    'Неверный email или пароль.',
    'Невірний email або пароль.',
    'Wrong email or password.',
  );
  String get emailBereitsRegistriert => _t(
    'Diese E-Mail ist bereits registriert.',
    'Этот email уже зарегистрирован.',
    'Цей email вже зареєстрований.',
    'This email is already registered.',
  );
  String get passwortZuSchwach => _t(
    'Passwort zu einfach (mindestens 6 Zeichen).',
    'Пароль слишком простой (минимум 6 символов).',
    'Пароль занадто простий (мінімум 6 символів).',
    'Password too weak (at least 6 characters).',
  );
  String get anmeldefehler => _t(
    'Anmeldefehler.',
    'Ошибка авторизации.',
    'Помилка авторизації.',
    'Sign-in error.',
  );

  // ── Import ───────────────────────────────────────────────────────────────
  String get importPdf =>
      _t('PDF importieren', 'Импорт PDF', 'Імпорт PDF', 'Import PDF');
  String get pdfMitUebungenWaehlen => _t(
    'PDF mit Übungen wählen',
    'Выберите PDF с упражнениями',
    'Виберіть PDF із вправами',
    'Choose a PDF with exercises',
  );
  String get importPickerHint => _t(
    'telc B2 Beruf — Lesen, Hören, Sprachbausteine,\n'
        'Beschwerde, Telefonnotiz. Die KI findet die Abschnitte\n'
        'selbst, auch wenn das PDF anders aufgebaut ist.',
    'telc B2 Beruf — Lesen, Hören, Sprachbausteine,\n'
        'Beschwerde, Telefonnotiz. ИИ сам находит разделы,\n'
        'даже если PDF оформлен иначе, чем обычно.',
    'telc B2 Beruf — Lesen, Hören, Sprachbausteine,\n'
        'Beschwerde, Telefonnotiz. ШІ сам знаходить розділи,\n'
        'навіть якщо PDF оформлено інакше, ніж зазвичай.',
    'telc B2 Beruf — Lesen, Hören, Sprachbausteine,\n'
        'Beschwerde, Telefonnotiz. The AI finds the sections\n'
        'itself, even if the PDF is laid out differently.',
  );
  String get pdfWaehlen =>
      _t('PDF wählen', 'Выбрать PDF', 'Вибрати PDF', 'Choose PDF');
  String get vollstaendigeAnalyseDauer => _t(
    'Die vollständige Analyse dauert 5–10 Minuten',
    'Полный разбор занимает 5–10 минут',
    'Повний розбір триває 5–10 хвилин',
    'Full analysis takes 5–10 minutes',
  );
  String get pdfKonvertierung => _t(
    'PDF wird konvertiert…',
    'Конвертация PDF…',
    'Конвертація PDF…',
    'Converting PDF…',
  );
  String get cachePruefung => _t(
    'Cache wird geprüft…',
    'Проверка кеша…',
    'Перевірка кешу…',
    'Checking cache…',
  );
  String get dokumentstrukturAnalyse => _t(
    'Dokumentstruktur wird analysiert…',
    'Анализ структуры документа…',
    'Аналіз структури документа…',
    'Analyzing document structure…',
  );
  String abschnitteAnalyse(String label, int i, int total) => _t(
    'Abschnitte werden analysiert… $label ($i/$total)',
    'Разбор разделов… $label ($i/$total)',
    'Розбір розділів… $label ($i/$total)',
    'Parsing sections… $label ($i/$total)',
  );
  String variantePart(int done, int total) => _t(
    '\nVariante $done von $total',
    '\nвариант $done из $total',
    '\nваріант $done з $total',
    '\nvariant $done of $total',
  );
  String get keinUebungErkannt => _t(
    'In dieser Datei konnte keine Übung erkannt werden.',
    'В этом файле не удалось распознать ни одного упражнения.',
    'У цьому файлі не вдалося розпізнати жодної вправи.',
    'No exercise could be recognized in this file.',
  );
  String get speichern =>
      _t('Wird gespeichert…', 'Сохранение…', 'Збереження…', 'Saving…');
  String get mancheAbschnitteFehler => _t(
    'Einige Abschnitte konnten nicht analysiert werden',
    'Некоторые разделы не удалось разобрать',
    'Деякі розділи не вдалося розібрати',
    'Some sections could not be parsed',
  );
  String get verstanden => _t('Verstanden', 'Понятно', 'Зрозуміло', 'Got it');
  // CR-11: distinct, actionable import-error copy per backend failure kind
  // (401/403/413/429/timeout/5xx) instead of one generic retry message for
  // everything — see ApiException in services/api_exception.dart.
  String get importFehlerSitzungAbgelaufen => _t(
    'Deine Sitzung ist abgelaufen. Bitte melde dich erneut an.',
    'Сессия истекла. Пожалуйста, войдите снова.',
    'Сесія закінчилася. Будь ласка, увійдіть знову.',
    'Your session has expired. Please sign in again.',
  );
  String get importFehlerPremiumErforderlich => _t(
    'Dieses Dokument ist neu und erfordert Premium — bereits '
        'bearbeitete Dokumente kannst du weiterhin kostenlos öffnen.',
    'Этот документ ещё не обрабатывался — для новых документов нужен '
        'Premium. Уже обработанные документы по-прежнему доступны бесплатно.',
    'Цей документ ще не оброблявся — для нових документів потрібен '
        'Premium. Уже оброблені документи, як і раніше, доступні безкоштовно.',
    'This document is new and requires Premium — already-processed '
        'documents remain free to open.',
  );
  String get importFehlerDateiZuGross => _t(
    'Die Datei ist für den Server zu groß.',
    'Файл слишком большой для сервера.',
    'Файл завеликий для сервера.',
    'The file is too large for the server to process.',
  );
  String get importFehlerRateLimit => _t(
    'Zu viele Anfragen — bitte versuche es später erneut.',
    'Слишком много запросов — попробуйте позже.',
    'Забагато запитів — спробуйте пізніше.',
    'Too many requests right now — please try again later.',
  );
  String get importFehlerVerbindung => _t(
    'Verbindungsproblem. Bitte überprüfe deine Internetverbindung und '
        'versuche es erneut.',
    'Проблема с подключением. Проверьте интернет-соединение и попробуйте '
        'ещё раз.',
    'Проблема з підключенням. Перевірте інтернет-з\'єднання і спробуйте '
        'ще раз.',
    'Connection problem. Please check your internet connection and try '
        'again.',
  );

  // ── Course ───────────────────────────────────────────────────────────────
  String get pruefungsteile =>
      _t('Prüfungsteile', 'Разделы экзамена', 'Розділи іспиту', 'Exam parts');
  String get kursNichtGefunden => _t(
    'Kurs nicht gefunden',
    'Курс не найден',
    'Курс не знайдено',
    'Course not found',
  );
  String get abschnitteNichtErkannt => _t(
    'Die Abschnitte wurden nicht erkannt. Bitte importieren Sie das PDF erneut.',
    'Разделы не распознаны. Попробуйте импортировать PDF ещё раз.',
    'Розділи не розпізнано. Спробуйте імпортувати PDF ще раз.',
    'Sections were not recognized. Try importing the PDF again.',
  );

  // ── Section list ─────────────────────────────────────────────────────────
  String get keineVarianten =>
      _t('Keine Varianten', 'Нет вариантов', 'Немає варіантів', 'No variants');
  String get varianteWaehlen => _t(
    'Variante wählen',
    'Выберите вариант',
    'Виберіть варіант',
    'Choose a variant',
  );
  String variante(num n) =>
      _t('Variante $n', 'Вариант $n', 'Варіант $n', 'Variant $n');
  String varianteMitVersion(num n, String version) => _t(
    'Variante $n · $version',
    'Вариант $n · $version',
    'Варіант $n · $version',
    'Variant $n · $version',
  );

  // ── Exercises (shared across all exercise screen types) ────────────────
  // Note: "Richtig"/"Falsch" and telc section names (e.g. "Hören Teil 1")
  // are left in German everywhere — they're the exam's own terminology,
  // same as the exam content itself, not app chrome.
  String get bitteAlleAufgabenBeantworten => _t(
    'Bitte alle Aufgaben beantworten.',
    'Пожалуйста, ответьте на все задания.',
    'Будь ласка, дайте відповідь на всі завдання.',
    'Please answer all tasks.',
  );
  String get pruefen => _t('Prüfen', 'Проверить', 'Перевірити', 'Check');
  String get antworten => _t('Antworten', 'Ответы', 'Відповіді', 'Answers');
  String get antwortenZeigen => _t(
    'Antworten zeigen',
    'Показать ответы',
    'Показати відповіді',
    'Show answers',
  );
  String get neuVersuchen =>
      _t('Neu versuchen', 'Попробовать снова', 'Спробувати знову', 'Try again');
  String vonRichtig(int correct, int total) => _t(
    '$correct von $total richtig',
    '$correct из $total правильно',
    '$correct з $total правильно',
    '$correct out of $total correct',
  );
  String aufgabeNummer(int n) =>
      _t('Aufgabe $n', 'Задание $n', 'Завдання $n', 'Task $n');

  // ── Telefonnotiz ─────────────────────────────────────────────────────────
  String telefonnotizVariante(num n) => _t(
    'Telefonnotiz · Variante $n',
    'Telefonnotiz · Вариант $n',
    'Telefonnotiz · Варіант $n',
    'Telefonnotiz · Variant $n',
  );
  String get aufnahmeAnhoeren => _t(
    'Aufnahme anhören',
    'Слушать запись',
    'Слухати запис',
    'Listen to recording',
  );
  String get anrufTyp =>
      _t('Art des Anrufs', 'Тип звонка', 'Тип дзвінка', 'Call type');
  String get name => _t('Name', 'Имя', "Ім'я", 'Name');
  String get telefon => _t('Telefon', 'Телефон', 'Телефон', 'Phone');
  String get zuErledigen =>
      _t('Zu erledigen', 'К исполнению', 'До виконання', 'To do');
  String get weitereInformationen => _t(
    'Weitere Informationen:',
    'Дополнительная информация:',
    'Додаткова інформація:',
    'Additional information:',
  );
  String get ausblenden => _t('Ausblenden', 'Скрыть', 'Приховати', 'Hide');
  String get antwortNachAnhoerenHint => _t(
    'Tippen Sie nach dem Anhören auf „Antworten"',
    'Нажмите «Ответы» после прослушивания',
    'Натисніть «Відповіді» після прослуховування',
    'Tap "Answers" after listening',
  );

  // ── Universal exercise ──────────────────────────────────────────────────
  String get frageNichtInQuelle => _t(
    'Für diese Frage gibt es keine Antwort in der Quelle.',
    'Для этого вопроса в источнике нет ответа.',
    'Для цього питання в джерелі немає відповіді.',
    'This question has no answer in the source.',
  );

  // ── Sprachbausteine ──────────────────────────────────────────────────────
  String get wortliste =>
      _t('WORTLISTE', 'СПИСОК СЛОВ', 'СПИСОК СЛІВ', 'WORD LIST');
  String lueckeAuswaehlen(int n) => _t(
    'Lücke $n, Antwort auswählen',
    'Пропуск $n, выбрать ответ',
    'Пропуск $n, вибрати відповідь',
    'Gap $n, choose answer',
  );

  // ── Beschwerde ───────────────────────────────────────────────────────────
  String get internerHinweis => _t(
    'INTERNER HINWEIS',
    'ВНУТРЕННЯЯ ЗАПИСКА',
    'ВНУТРІШНЯ ЗАПИСКА',
    'INTERNAL NOTE',
  );
  String get kundenbeschwerde => _t(
    'KUNDENBESCHWERDE',
    'ЖАЛОБА КЛИЕНТА',
    'СКАРГА КЛІЄНТА',
    'CUSTOMER COMPLAINT',
  );
  String get antwortbogen =>
      _t('ANTWORTBOGEN', 'БЛАНК ОТВЕТА', 'БЛАНК ВІДПОВІДІ', 'ANSWER SHEET');
  String woerterCount(int count, int max) => _t(
    'Wörter: $count / $max',
    'Слов: $count / $max',
    'Слів: $count / $max',
    'Words: $count / $max',
  );
  String get zeitAbgelaufen =>
      _t('Zeit abgelaufen', 'Время истекло', 'Час вийшов', 'Time is up');
  String get schreibenHint => _t(
    'Geben Sie einen Text ein, und der Timer startet automatisch.',
    'Начните печатать текст — таймер запустится автоматически.',
    'Почніть друкувати текст — таймер запуститься автоматично.',
    'Start typing and the timer will start automatically.',
  );
  String get fertig => _t('Fertig', 'Готово', 'Готово', 'Done');
  String get musterantwort =>
      _t('MUSTERANTWORT', 'ОБРАЗЕЦ ОТВЕТА', 'ЗРАЗОК ВІДПОВІДІ', 'MODEL ANSWER');
  String get fragenZuDenTexten => _t(
    'FRAGEN ZU DEN TEXTEN',
    'ВОПРОСЫ К ТЕКСТАМ',
    'ПИТАННЯ ДО ТЕКСТІВ',
    'QUESTIONS ON THE TEXTS',
  );

  // ── Universal exercise screen ───────────────────────────────────────────
  String instruktion(String sectionType) => switch (sectionType) {
    'lesen_teil1' => _t(
      'Lesen Sie die Texte. Welcher Text passt zu welcher Person? '
          'Nicht alle Texte werden gebraucht.',
      'Прочитайте тексты. Какой текст подходит какому человеку? '
          'Не все тексты нужны.',
      'Прочитайте тексти. Який текст підходить якій людині? '
          'Не всі тексти потрібні.',
      'Read the texts. Which text matches which person? '
          'Not all texts are needed.',
    ),
    'lesen_teil2' => _t(
      'Lesen Sie den Text und lösen Sie die Aufgaben.',
      'Прочитайте текст и выполните задания.',
      'Прочитайте текст і виконайте завдання.',
      'Read the text and solve the tasks.',
    ),
    'lesen_teil3' => _t(
      'Welche Antwort passt zu welcher Situation? '
          '„x" bedeutet: kein Text passt.',
      'Какой ответ подходит какой ситуации? '
          '«x» означает: ни один текст не подходит.',
      'Яка відповідь підходить якій ситуації? '
          '«x» означає: жоден текст не підходить.',
      'Which reply matches which situation? '
          '"x" means: no text fits.',
    ),
    'lesen_teil4' => _t(
      'Lesen Sie das Protokoll und lösen Sie die Aufgaben.',
      'Прочитайте протокол и выполните задания.',
      'Прочитайте протокол і виконайте завдання.',
      'Read the minutes and solve the tasks.',
    ),
    'beschwerde' => _t(
      'Lesen Sie die Briefe und lösen Sie die Aufgaben. '
          'Die Musterantwort ist ein Beispiel für den Schreibteil.',
      'Прочитайте письма и выполните задания. '
          'Образец ответа — пример для письменной части.',
      'Прочитайте листи і виконайте завдання. '
          'Зразок відповіді — приклад для письмової частини.',
      'Read the letters and solve the tasks. '
          'The model answer is an example for the writing part.',
    ),
    'sprachbausteine_teil2' => _t(
      'Wählen Sie für jede Lücke die richtige Lösung.',
      'Выберите правильный вариант для каждого пропуска.',
      'Виберіть правильний варіант для кожного пропуску.',
      'Choose the right option for each gap.',
    ),
    'hoeren_teil2' => _t(
      'Hören Sie die Gespräche. Welche Aussage passt zu welchem Gespräch?',
      'Прослушайте разговоры. Какое утверждение подходит какому разговору?',
      'Прослухайте розмови. Яке твердження підходить якій розмові?',
      'Listen to the conversations. Which statement matches which conversation?',
    ),
    'hoeren_teil3' => _t(
      'Hören Sie das Gespräch und lösen Sie die Aufgaben.',
      'Прослушайте разговор и выполните задания.',
      'Прослухайте розмову і виконайте завдання.',
      'Listen to the conversation and solve the tasks.',
    ),
    'hoeren_teil4' => _t(
      'Hören Sie die Nachrichten und lösen Sie die Aufgaben.',
      'Прослушайте сообщения и выполните задания.',
      'Прослухайте повідомлення і виконайте завдання.',
      'Listen to the messages and solve the tasks.',
    ),
    _ => _t(
      'Lösen Sie die Aufgaben.',
      'Выполните задания.',
      'Виконайте завдання.',
      'Solve the tasks.',
    ),
  };
  String get transkript =>
      _t('Transkript', 'Транскрипт', 'Транскрипт', 'Transcript');
  String get texteLesen =>
      _t('Texte lesen', 'Читать тексты', 'Читати тексти', 'Read texts');
  // CR-15: DialogueAudioPlayer's own strings — reused by the hoeren_teil1,
  // telefonnotiz and universal exercise screens.
  String get dialogAnhoeren => _t(
    'Dialog anhören',
    'Прослушать диалог',
    'Прослухати діалог',
    'Listen to dialogue',
  );
  String get pausieren => _t('Pause', 'Пауза', 'Пауза', 'Pause');
  String get weiterhoeren => _t('Weiter', 'Продолжить', 'Продовжити', 'Resume');
  String audioWirdGeneriert(int done, int total) => _t(
    'Audio wird generiert… $done/$total',
    'Генерация аудио… $done/$total',
    'Генерація аудіо… $done/$total',
    'Generating audio… $done/$total',
  );
  String get textDialog =>
      _t('Textdialog', 'Текст диалога', 'Текст діалогу', 'Dialogue text');
  String get textAufnahme =>
      _t('Text der Aufnahme', 'Текст записи', 'Текст запису', 'Recording text');
  String get audioNeuGenerieren => _t(
    'Audio neu generieren',
    'Заново сгенерировать аудио',
    'Знову згенерувати аудіо',
    'Regenerate audio',
  );
  String get wiederholenAction =>
      _t('Wiederholen', 'Повторить', 'Повторити', 'Retry');
  String get fehlerBeimGenerieren => _t(
    'Fehler beim Generieren',
    'Ошибка при генерации',
    'Помилка під час генерації',
    'Error while generating',
  );
  String get text => _t('Text', 'Текст', 'Текст', 'Text');
  String get aussagen =>
      _t('AUSSAGEN', 'УТВЕРЖДЕНИЯ', 'ТВЕРДЖЕННЯ', 'STATEMENTS');
  String get aufgaben => _t('Aufgaben', 'Задания', 'Завдання', 'Tasks');
  String get ausgezeichnetAllesRichtig => _t(
    'Ausgezeichnet! Alles richtig!',
    'Отлично! Всё правильно!',
    'Чудово! Все правильно!',
    'Excellent! All correct!',
  );
  String get schauenSieFalscheAntworten => _t(
    'Schauen Sie die falschen Antworten an.',
    'Посмотрите неправильные ответы.',
    'Перегляньте неправильні відповіді.',
    'Take a look at the wrong answers.',
  );

  // ── Sprechen (Mündliche Prüfung) ─────────────────────────────────────────
  String get niveauWaehlen => _t(
    'Niveau wählen',
    'Выберите уровень',
    'Виберіть рівень',
    'Choose a level',
  );
  String teileThemen(int teile, int themen) => _t(
    '$teile Teile · $themen Themen',
    '$teile части · $themen тем',
    '$teile частини · $themen тем',
    '$teile parts · $themen topics',
  );
  String get demnaechst => _t('Bald', 'Скоро', 'Скоро', 'Coming soon');
  String get themenFuersSprechen => _t(
    'B2 Beruf · Themen für die mündliche Prüfung',
    'B2 Beruf · Темы для говорения',
    'B2 Beruf · Теми для говоріння',
    'B2 Beruf · Speaking topics',
  );
  String get uebungstypWaehlen => _t(
    'Wählen Sie einen Übungstyp:',
    'Выберите тип упражнения:',
    'Виберіть тип вправи:',
    'Choose an exercise type:',
  );
  String get sprechenTeil1Subtitle => _t(
    '8 Themen · Monolog · 2 Minuten sprechen',
    '8 тем · Монолог · говорить 2 минуты',
    '8 тем · Монолог · говорити 2 хвилини',
    '8 topics · Monologue · speak for 2 minutes',
  );
  String get sprechenTeil2Subtitle => _t(
    '73 Themen · Smalltalk · Dialog und Reaktion',
    '73 темы · Смолток · диалог и реакция',
    '73 теми · Смолток · діалог і реакція',
    '73 topics · Small talk · dialogue and reaction',
  );
  String get sprechenTeil3Subtitle => _t(
    '66 Situationen · Lösungswege diskutieren',
    '66 ситуаций · обсуждение путей решения',
    '66 ситуацій · обговорення шляхів вирішення',
    '66 situations · discuss solutions',
  );
  String get monolog2Minuten => _t(
    'Monolog · 2 Minuten',
    'Монолог · 2 минуты',
    'Монолог · 2 хвилини',
    'Monologue · 2 minutes',
  );
  String get playUndSprechenHint => _t(
    'Drücken Sie Play und sprechen Sie 2 Minuten',
    'Нажмите Play и говорите 2 минуты',
    'Натисніть Play і говоріть 2 хвилини',
    'Press Play and speak for 2 minutes',
  );
  String get loesungswegeDiskutieren => _t(
    'Lösungswege diskutieren',
    'Обсуждение путей решения',
    'Обговорення шляхів вирішення',
    'Discuss solutions',
  );
  String get smalltalkDialog => _t(
    'Smalltalk · Dialog',
    'Смолток · диалог',
    'Смолток · діалог',
    'Small talk · dialogue',
  );
  String get redemittel => _t(
    'REDEMITTEL',
    'РЕЧЕВЫЕ ОБОРОТЫ',
    'МОВЛЕННЄВІ ЗВОРОТИ',
    'USEFUL PHRASES',
  );
  String get aufgabeLabel => _t('AUFGABE', 'ЗАДАНИЕ', 'ЗАВДАННЯ', 'TASK');
  String get redezeit =>
      _t('REDEZEIT', 'ВРЕМЯ НА ОТВЕТ', 'ЧАС НА ВІДПОВІДЬ', 'SPEAKING TIME');
  String get zeitAbgelaufenAusruf =>
      _t('Zeit abgelaufen!', 'Время истекло!', 'Час вийшов!', 'Time is up!');
  String get pause => _t('Pause', 'Пауза', 'Пауза', 'Pause');
  String get weiter => _t('Weiter', 'Продолжить', 'Продовжити', 'Continue');
  String get start => _t('Start', 'Начать', 'Почати', 'Start');
  String get zuruecksetzen => _t('Reset', 'Сбросить', 'Скинути', 'Reset');

  // ── Smalltalk exercise ──
  String get gespraechspartnerSagt => _t(
    'Ihr Gesprächspartner sagt:',
    'Ваш собеседник говорит:',
    'Ваш співрозмовник каже:',
    'Your conversation partner says:',
  );
  String get reagierenSieAufAussage => _t(
    'Reagieren Sie auf die Aussage Ihres Gesprächspartners.',
    'Отреагируйте на высказывание собеседника.',
    'Відреагуйте на висловлювання співрозмовника.',
    'React to your conversation partner\'s statement.',
  );
  String get beispieldialog => _t(
    'BEISPIELDIALOG',
    'ПРИМЕР ДИАЛОГА',
    'ПРИКЛАД ДІАЛОГУ',
    'SAMPLE DIALOGUE',
  );
  String get alternativsaetze => _t(
    'ALTERNATIVSÄTZE',
    'АЛЬТЕРНАТИВНЫЕ ФРАЗЫ',
    'АЛЬТЕРНАТИВНІ ФРАЗИ',
    'ALTERNATIVE PHRASES',
  );

  // ── Sprechen Teil 3 exercise ──
  String situationNummer(int n) =>
      _t('Situation $n', 'Ситуация $n', 'Ситуація $n', 'Situation $n');
  String situationVon(int n, int total) => _t(
    'Situation $n von $total',
    'Ситуация $n из $total',
    'Ситуація $n з $total',
    'Situation $n of $total',
  );
  String get diskussionspunkte => _t(
    'Diskussionspunkte',
    'Пункты для обсуждения',
    'Пункти для обговорення',
    'Discussion points',
  );
  String get beispieldialogTitel => _t(
    'Beispieldialog',
    'Пример диалога',
    'Приклад діалогу',
    'Sample dialogue',
  );
  String get redemittelTitel => _t(
    'Redemittel',
    'Речевые обороты',
    'Мовленнєві звороти',
    'Useful phrases',
  );

  // ── Legal: link labels / consent ──────────────────────────────────────────
  String get datenschutz =>
      _t('Datenschutz', 'Конфиденциальность', 'Конфіденційність', 'Privacy');
  String get datenschutzerklaerung => _t(
    'Datenschutzerklärung',
    'Политика конфиденциальности',
    'Політика конфіденційності',
    'Privacy Policy',
  );
  String get impressum =>
      _t('Impressum', 'Выходные данные', 'Вихідні дані', 'Legal Notice');
  String get nutzungsbedingungen => _t(
    'Nutzungsbedingungen',
    'Условия использования',
    'Умови використання',
    'Terms of Use',
  );
  String get ichAkzeptiereDie =>
      _t('Ich akzeptiere die ', 'Я принимаю ', 'Я приймаю ', 'I accept the ');
  String get undDie => _t(' und die ', ' и ', ' та ', ' and the ');
  String get bitteDatenschutzZustimmen => _t(
    'Bitte stimme der Datenschutzerklärung und den Nutzungsbedingungen zu',
    'Пожалуйста, примите политику конфиденциальности и условия использования',
    'Будь ласка, прийміть політику конфіденційності та умови використання',
    'Please accept the privacy policy and terms of use',
  );

  // ── Impressum ─────────────────────────────────────────────────────────────
  String get impressumTitel =>
      _t('Impressum', 'Выходные данные', 'Вихідні дані', 'Legal Notice');
  String get impressumAngaben => _t(
    'Angaben gemäß § 5 TMG',
    'Сведения согласно § 5 TMG (Германия)',
    'Відомості згідно § 5 TMG (Німеччина)',
    'Information pursuant to § 5 TMG (Germany)',
  );
  String get impressumAngabenBody => _t(
    'Ihor Bondarenko\nUkraine\nE-Mail: linguaproapps@gmail.com',
    'Ihor Bondarenko\nУкраина\nE-Mail: linguaproapps@gmail.com',
    'Ihor Bondarenko\nУкраїна\nE-Mail: linguaproapps@gmail.com',
    'Ihor Bondarenko\nUkraine\nE-Mail: linguaproapps@gmail.com',
  );
  String get impressumVerantwortlich => _t(
    'Verantwortlich für den Inhalt',
    'Ответственный за содержание',
    'Відповідальний за зміст',
    'Responsible for Content',
  );
  String get impressumHaftung => _t(
    'Haftungsausschluss',
    'Отказ от ответственности',
    'Відмова від відповідальності',
    'Disclaimer',
  );
  String get impressumHaftungBody => _t(
    'Die App verarbeitet von Nutzern hochgeladene Dokumente automatisch mit '
        'KI. Für die Richtigkeit, Vollständigkeit und Aktualität der daraus '
        'erzeugten Übungen kann keine Gewähr übernommen werden. Für die Inhalte '
        'der hochgeladenen Dokumente sind die Nutzer selbst verantwortlich.',
    'Приложение автоматически обрабатывает загруженные пользователями '
        'документы с помощью ИИ. Мы не можем гарантировать точность, полноту и '
        'актуальность созданных на их основе упражнений. За содержание '
        'загружаемых документов ответственность несут сами пользователи.',
    'Застосунок автоматично обробляє завантажені користувачами документи за '
        'допомогою ШІ. Ми не можемо гарантувати точність, повноту та '
        'актуальність створених на їх основі вправ. За вміст завантажених '
        'документів відповідальність несуть самі користувачі.',
    'The app automatically processes user-uploaded documents using AI. No '
        'guarantee can be given for the accuracy, completeness and currentness '
        'of the exercises generated from them. Users are solely responsible for '
        'the content of the documents they upload.',
  );
  String get impressumUrheberrecht =>
      _t('Urheberrecht', 'Авторское право', 'Авторське право', 'Copyright');
  String get impressumUrheberrechtBody => _t(
    'Die durch den App-Entwickler erstellten Inhalte und Werke in dieser App '
        'unterliegen dem Urheberrecht. Die Vervielfältigung, Bearbeitung, '
        'Verbreitung und jede Art der Verwertung außerhalb der Grenzen des '
        'Urheberrechtes bedürfen der schriftlichen Zustimmung des jeweiligen '
        'Autors bzw. Erstellers.',
    'Весь контент и материалы в этом приложении, созданные разработчиком, '
        'защищены авторским правом. Воспроизведение, обработка, распространение '
        'и любое использование за пределами авторского права требуют письменного '
        'согласия автора.',
    'Весь контент і матеріали в цьому застосунку, створені розробником, '
        'захищені авторським правом. Відтворення, обробка, поширення та '
        'будь-яке використання за межами авторського права вимагають письмової '
        'згоди автора.',
    'The content and works created by the app developer in this app are '
        'subject to copyright law. Reproduction, editing, distribution and any '
        'kind of use beyond the limits of copyright require written consent of '
        'the author.',
  );
  String get impressumTelcHinweis =>
      _t('telc Hinweis', 'Примечание telc', 'Примітка telc', 'telc Notice');
  String get impressumTelcBody => _t(
    'Diese App ist ein inoffizielles Lernhilfsmittel für die Vorbereitung '
        'auf Deutschprüfungen im telc-Format. telc ist eine eingetragene Marke '
        'der telc GmbH. Diese App steht in keiner Verbindung zur telc GmbH.',
    'Это приложение является неофициальным учебным пособием для подготовки '
        'к экзаменам по немецкому языку в формате telc. telc является '
        'зарегистрированной торговой маркой telc GmbH. Это приложение не '
        'связано с telc GmbH.',
    'Цей застосунок є неофіційним навчальним посібником для підготовки до '
        'іспитів з німецької мови у форматі telc. telc є зареєстрованою '
        'торговою маркою telc GmbH. Цей застосунок не пов\'язаний з telc GmbH.',
    'This app is an unofficial learning aid for preparation for German '
        'exams in telc format. telc is a registered trademark of telc GmbH. '
        'This app is not affiliated with telc GmbH.',
  );

  // ── Privacy Policy ────────────────────────────────────────────────────────
  String get datenschutzTitel => _t(
    'Datenschutzerklärung',
    'Политика конфиденциальности',
    'Політика конфіденційності',
    'Privacy Policy',
  );
  String get datenschutz1 => _t(
    '1. Verantwortlicher',
    '1. Ответственный',
    '1. Відповідальний',
    '1. Controller',
  );
  String get datenschutz1Body => _t(
    'Ihor Bondarenko, Ukraine\nE-Mail: linguaproapps@gmail.com',
    'Ihor Bondarenko, Украина\nE-Mail: linguaproapps@gmail.com',
    'Ihor Bondarenko, Україна\nE-Mail: linguaproapps@gmail.com',
    'Ihor Bondarenko, Ukraine\nE-Mail: linguaproapps@gmail.com',
  );
  String get datenschutz2 => _t(
    '2. Welche Daten wir erheben',
    '2. Какие данные мы собираем',
    '2. Які дані ми збираємо',
    '2. Data We Collect',
  );
  String get datenschutz2Body => _t(
    '• E-Mail-Adresse, Name und Profilbild (bei Anmeldung)\n'
        '• Inhalte der von dir hochgeladenen PDF-Dokumente\n'
        '• Kontostatus (kostenlos / Premium)\n'
        '• Technische Anfragedaten zur Missbrauchsvermeidung (Rate-Limiting)',
    '• E-Mail, имя и фото профиля (при входе)\n'
        '• Содержимое загружаемых вами PDF-документов\n'
        '• Статус аккаунта (бесплатный / премиум)\n'
        '• Технические данные запросов для защиты от злоупотреблений',
    '• E-Mail, ім\'я та фото профілю (при вході)\n'
        '• Вміст завантажених вами PDF-документів\n'
        '• Статус акаунта (безкоштовний / преміум)\n'
        '• Технічні дані запитів для захисту від зловживань',
    '• Email address, name and profile photo (upon sign-in)\n'
        '• Content of the PDF documents you upload\n'
        '• Account status (free / premium)\n'
        '• Technical request data for abuse prevention (rate limiting)',
  );
  String get datenschutz3 => _t(
    '3. Zweck der Datenverarbeitung',
    '3. Цель обработки данных',
    '3. Мета обробки даних',
    '3. Purpose of Processing',
  );
  String get datenschutz3Body => _t(
    'Deine Daten werden ausschließlich verwendet, um:\n'
        '• Dein Konto zu verwalten\n'
        '• Aus deinen Dokumenten Übungen zu erzeugen\n'
        '• Premium-Funktionen bereitzustellen\n'
        '• Missbrauch des Dienstes zu verhindern',
    'Ваши данные используются исключительно для:\n'
        '• Управления вашим аккаунтом\n'
        '• Создания упражнений из ваших документов\n'
        '• Предоставления премиум-функций\n'
        '• Предотвращения злоупотреблений сервисом',
    'Ваші дані використовуються виключно для:\n'
        '• Управління вашим акаунтом\n'
        '• Створення вправ із ваших документів\n'
        '• Надання преміум-функцій\n'
        '• Запобігання зловживанням сервісом',
    'Your data is used exclusively to:\n'
        '• Manage your account\n'
        '• Generate exercises from your documents\n'
        '• Provide premium features\n'
        '• Prevent abuse of the service',
  );
  String get datenschutz4 => _t(
    '4. Drittanbieter',
    '4. Сторонние сервисы',
    '4. Сторонні сервіси',
    '4. Third-Party Services',
  );
  String get datenschutz4Body => _t(
    'Wir verwenden folgende Drittanbieter-Dienste:\n\n'
        'Firebase (Google LLC)\n'
        'Für Authentifizierung und Speicherung des Kontostatus.\n'
        'Datenschutzrichtlinie: policies.google.com/privacy\n\n'
        'Google Sign-In (Google LLC)\n'
        'Optionale Anmeldemethode.\n\n'
        'Google Gemini AI (Google LLC)\n'
        'Der Text deiner hochgeladenen Dokumente wird zur Erzeugung der Übungen '
        'an Gemini übermittelt, aber dort nicht dauerhaft gespeichert.\n\n'
        'Vercel Inc.\n'
        'Hosting des Backends. Hochgeladene Dokumente werden dort nur zur '
        'Verarbeitung im Arbeitsspeicher gehalten.\n\n'
        'Upstash Inc.\n'
        'Zwischenspeicherung (Cache) der Verarbeitungsergebnisse, damit gleiche '
        'Dokumente nicht mehrfach kostenpflichtig verarbeitet werden.',
    'Мы используем следующие сторонние сервисы:\n\n'
        'Firebase (Google LLC)\n'
        'Для аутентификации и хранения статуса аккаунта.\n'
        'Политика конфиденциальности: policies.google.com/privacy\n\n'
        'Google Sign-In (Google LLC)\n'
        'Необязательный способ входа.\n\n'
        'Google Gemini AI (Google LLC)\n'
        'Текст загружаемых вами документов передаётся в Gemini для создания '
        'упражнений, но не хранится там постоянно.\n\n'
        'Vercel Inc.\n'
        'Хостинг серверной части. Загружаемые документы держатся там только в '
        'оперативной памяти во время обработки.\n\n'
        'Upstash Inc.\n'
        'Кеширование результатов обработки, чтобы одинаковые документы не '
        'обрабатывались платно повторно.',
    'Ми використовуємо такі сторонні сервіси:\n\n'
        'Firebase (Google LLC)\n'
        'Для автентифікації та зберігання статусу акаунта.\n'
        'Політика конфіденційності: policies.google.com/privacy\n\n'
        'Google Sign-In (Google LLC)\n'
        'Необов\'язковий спосіб входу.\n\n'
        'Google Gemini AI (Google LLC)\n'
        'Текст завантажених вами документів передається до Gemini для '
        'створення вправ, але не зберігається там постійно.\n\n'
        'Vercel Inc.\n'
        'Хостинг серверної частини. Завантажені документи тримаються там лише '
        'в оперативній пам\'яті під час обробки.\n\n'
        'Upstash Inc.\n'
        'Кешування результатів обробки, щоб однакові документи не оброблялися '
        'платно повторно.',
    'We use the following third-party services:\n\n'
        'Firebase (Google LLC)\n'
        'For authentication and storing account status.\n'
        'Privacy policy: policies.google.com/privacy\n\n'
        'Google Sign-In (Google LLC)\n'
        'Optional sign-in method.\n\n'
        'Google Gemini AI (Google LLC)\n'
        'The text of your uploaded documents is transmitted to Gemini to '
        'generate exercises, but is not stored there permanently.\n\n'
        'Vercel Inc.\n'
        'Backend hosting. Uploaded documents are only held in memory during '
        'processing.\n\n'
        'Upstash Inc.\n'
        'Caching of processing results so identical documents are not '
        'processed (and billed) repeatedly.',
  );
  String get datenschutz5 => _t(
    '5. Datenweitergabe',
    '5. Передача данных',
    '5. Передача даних',
    '5. Data Sharing',
  );
  String get datenschutz5Body => _t(
    'Deine Daten werden nicht an Dritte verkauft oder weitergegeben, außer '
        'an die oben genannten Dienstleister, die zur Bereitstellung der '
        'App-Funktionalität erforderlich sind.',
    'Ваши данные не продаются и не передаются третьим лицам, за исключением '
        'вышеуказанных поставщиков услуг, необходимых для работы приложения.',
    'Ваші дані не продаються і не передаються третім особам, за винятком '
        'вищезазначених постачальників послуг, необхідних для роботи застосунку.',
    'Your data is not sold or shared with third parties, except with the '
        'service providers listed above that are necessary to provide the app '
        'functionality.',
  );
  String get datenschutz6 => _t(
    '6. Datenspeicherung',
    '6. Хранение данных',
    '6. Зберігання даних',
    '6. Data Storage',
  );
  String get datenschutz6Body => _t(
    'Die aus deinen Dokumenten erzeugten Übungen werden lokal auf deinem '
        'Gerät gespeichert und können jederzeit von dir gelöscht werden. '
        'Kontodaten liegen in Firebase (Google Cloud). Nach Löschung deines '
        'Kontos werden alle personenbezogenen Daten innerhalb von 30 Tagen '
        'endgültig gelöscht.',
    'Созданные из ваших документов упражнения хранятся локально на вашем '
        'устройстве и могут быть удалены вами в любой момент. Данные аккаунта '
        'находятся в Firebase (Google Cloud). После удаления аккаунта все '
        'персональные данные будут окончательно удалены в течение 30 дней.',
    'Створені з ваших документів вправи зберігаються локально на вашому '
        'пристрої та можуть бути видалені вами будь-коли. Дані акаунта '
        'знаходяться у Firebase (Google Cloud). Після видалення акаунта всі '
        'персональні дані будуть остаточно видалені протягом 30 днів.',
    'The exercises generated from your documents are stored locally on '
        'your device and can be deleted by you at any time. Account data is '
        'stored in Firebase (Google Cloud). After account deletion, all '
        'personal data will be permanently deleted within 30 days.',
  );
  String get datenschutz7 => _t(
    '7. Deine Rechte (DSGVO)',
    '7. Ваши права (GDPR)',
    '7. Ваші права (GDPR)',
    '7. Your Rights (GDPR)',
  );
  String get datenschutz7Body => _t(
    'Du hast das Recht auf:\n'
        '• Auskunft über deine gespeicherten Daten\n'
        '• Berichtigung unrichtiger Daten\n'
        '• Löschung deiner Daten (Konto löschen)\n'
        '• Datenübertragbarkeit\n'
        '• Widerspruch gegen die Verarbeitung\n\n'
        'Zur Ausübung dieser Rechte kontaktiere uns unter:\n'
        'linguaproapps@gmail.com',
    'Вы имеете право на:\n'
        '• Информацию о хранимых данных\n'
        '• Исправление неверных данных\n'
        '• Удаление данных (удаление аккаунта)\n'
        '• Переносимость данных\n'
        '• Возражение против обработки данных\n\n'
        'Для реализации этих прав свяжитесь с нами:\n'
        'linguaproapps@gmail.com',
    'Ви маєте право на:\n'
        '• Інформацію про дані, що зберігаються\n'
        '• Виправлення неточних даних\n'
        '• Видалення даних (видалення акаунта)\n'
        '• Переносимість даних\n'
        '• Заперечення проти обробки даних\n\n'
        'Для реалізації цих прав зв\'яжіться з нами:\n'
        'linguaproapps@gmail.com',
    'You have the right to:\n'
        '• Access your stored data\n'
        '• Correction of inaccurate data\n'
        '• Deletion of your data (delete account)\n'
        '• Data portability\n'
        '• Object to processing\n\n'
        'To exercise these rights, contact us at:\n'
        'linguaproapps@gmail.com',
  );
  String get datenschutz8 =>
      _t('8. Kontakt', '8. Контакт', '8. Контакт', '8. Contact');
  String get datenschutz9 =>
      _t('9. Änderungen', '9. Изменения', '9. Зміни', '9. Changes');
  String get datenschutz9Body => _t(
    'Wir behalten uns vor, diese Datenschutzerklärung jederzeit zu '
        'aktualisieren. Letzte Aktualisierung: Juli 2026',
    'Мы оставляем за собой право обновлять эту политику конфиденциальности '
        'в любое время. Последнее обновление: июль 2026',
    'Ми залишаємо за собою право оновлювати цю політику конфіденційності в '
        'будь-який час. Останнє оновлення: липень 2026',
    'We reserve the right to update this privacy policy at any time. '
        'Last updated: July 2026',
  );

  // ── Terms of Use ──────────────────────────────────────────────────────────
  String get nutzungTitel => _t(
    'Nutzungsbedingungen',
    'Условия использования',
    'Умови використання',
    'Terms of Use',
  );
  String get nutzung1 => _t(
    '1. Geltungsbereich',
    '1. Область применения',
    '1. Сфера застосування',
    '1. Scope',
  );
  String get nutzung1Body => _t(
    'Diese Nutzungsbedingungen gelten für die Nutzung der App Exam Trainer. '
        'Mit der Registrierung erklärst du dich mit diesen Bedingungen '
        'einverstanden.',
    'Настоящие условия действуют при использовании приложения Exam Trainer. '
        'Регистрируясь, вы соглашаетесь с этими условиями.',
    'Ці умови діють при використанні застосунку Exam Trainer. '
        'Реєструючись, ви погоджуєтеся з цими умовами.',
    'These terms apply to the use of the Exam Trainer app. By registering '
        'you agree to these terms.',
  );
  String get nutzung2 => _t(
    '2. Leistungsbeschreibung',
    '2. Описание сервиса',
    '2. Опис сервісу',
    '2. Service Description',
  );
  String get nutzung2Body => _t(
    'Exam Trainer erzeugt aus von dir hochgeladenen PDF-Dokumenten '
        'automatisch interaktive Übungen mithilfe von KI. Im kostenlosen Konto '
        'wird pro Prüfungsbereich eine Variante verarbeitet; das Premium-Konto '
        'verarbeitet das gesamte Dokument. Der Funktionsumfang kann sich '
        'weiterentwickeln.',
    'Exam Trainer автоматически создаёт интерактивные упражнения из '
        'загружаемых вами PDF-документов с помощью ИИ. В бесплатном аккаунте '
        'обрабатывается один вариант на раздел экзамена; премиум-аккаунт '
        'обрабатывает весь документ. Функциональность может развиваться.',
    'Exam Trainer автоматично створює інтерактивні вправи із завантажених '
        'вами PDF-документів за допомогою ШІ. У безкоштовному акаунті '
        'обробляється один варіант на розділ іспиту; преміум-акаунт обробляє '
        'весь документ. Функціональність може розвиватися.',
    'Exam Trainer automatically generates interactive exercises from the '
        'PDF documents you upload using AI. The free account processes one '
        'variant per exam section; the premium account processes the entire '
        'document. Functionality may evolve over time.',
  );
  String get nutzung3 => _t(
    '3. Deine Inhalte und Verantwortung',
    '3. Ваши материалы и ответственность',
    '3. Ваші матеріали та відповідальність',
    '3. Your Content and Responsibility',
  );
  String get nutzung3Body => _t(
    'Du darfst nur Dokumente hochladen, zu deren Nutzung du berechtigt '
        'bist. Die erzeugten Übungen sind ausschließlich für dein persönliches '
        'Lernen bestimmt und dürfen nicht weiterverbreitet oder kommerziell '
        'genutzt werden. Das Hochladen rechtswidriger Inhalte ist untersagt.',
    'Вы можете загружать только документы, на использование которых у вас '
        'есть право. Созданные упражнения предназначены исключительно для '
        'вашего личного обучения и не могут распространяться или использоваться '
        'в коммерческих целях. Загрузка противоправного контента запрещена.',
    'Ви можете завантажувати лише документи, на використання яких у вас є '
        'право. Створені вправи призначені виключно для вашого особистого '
        'навчання і не можуть поширюватися або використовуватися в комерційних '
        'цілях. Завантаження протиправного контенту заборонено.',
    'You may only upload documents you are entitled to use. The generated '
        'exercises are intended exclusively for your personal learning and may '
        'not be redistributed or used commercially. Uploading unlawful content '
        'is prohibited.',
  );
  String get nutzung4 => _t(
    '4. KI-Hinweis',
    '4. Примечание об ИИ',
    '4. Примітка про ШІ',
    '4. AI Notice',
  );
  String get nutzung4Body => _t(
    'Die Übungen werden automatisch durch KI erzeugt und können Fehler '
        'enthalten. Die App ersetzt keine offizielle Prüfungsvorbereitung und '
        'garantiert keine Prüfungsergebnisse.',
    'Упражнения создаются автоматически с помощью ИИ и могут содержать '
        'ошибки. Приложение не заменяет официальную подготовку к экзамену и не '
        'гарантирует результатов экзамена.',
    'Вправи створюються автоматично за допомогою ШІ та можуть містити '
        'помилки. Застосунок не замінює офіційну підготовку до іспиту і не '
        'гарантує результатів іспиту.',
    'Exercises are generated automatically by AI and may contain errors. '
        'The app does not replace official exam preparation and does not '
        'guarantee exam results.',
  );
  String get nutzung5 => _t(
    '5. Verfügbarkeit und Haftung',
    '5. Доступность и ответственность',
    '5. Доступність та відповідальність',
    '5. Availability and Liability',
  );
  String get nutzung5Body => _t(
    'Die App wird ohne Gewähr auf ständige Verfügbarkeit bereitgestellt. '
        'Für Schäden durch Ausfälle, Datenverlust oder fehlerhafte '
        'KI-Ergebnisse wird — soweit gesetzlich zulässig — keine Haftung '
        'übernommen.',
    'Приложение предоставляется без гарантии постоянной доступности. '
        'Ответственность за ущерб из-за сбоев, потери данных или ошибочных '
        'результатов ИИ не принимается — в пределах, допустимых законом.',
    'Застосунок надається без гарантії постійної доступності. '
        'Відповідальність за збитки через збої, втрату даних або помилкові '
        'результати ШІ не приймається — у межах, дозволених законом.',
    'The app is provided without guarantee of continuous availability. To '
        'the extent permitted by law, no liability is accepted for damage '
        'caused by outages, data loss or incorrect AI results.',
  );
  String get nutzung6 => _t(
    '6. Sperrung und Kündigung',
    '6. Блокировка и прекращение',
    '6. Блокування та припинення',
    '6. Suspension and Termination',
  );
  String get nutzung6Body => _t(
    'Bei Missbrauch des Dienstes (z. B. Umgehung von Beschränkungen, '
        'automatisierte Massenanfragen, rechtswidrige Inhalte) kann dein Konto '
        'ohne Vorankündigung gesperrt werden. Du kannst dein Konto jederzeit '
        'löschen.',
    'При злоупотреблении сервисом (например, обход ограничений, '
        'автоматизированные массовые запросы, противоправный контент) ваш '
        'аккаунт может быть заблокирован без предупреждения. Вы можете удалить '
        'свой аккаунт в любой момент.',
    'У разі зловживання сервісом (наприклад, обхід обмежень, '
        'автоматизовані масові запити, протиправний контент) ваш акаунт може '
        'бути заблокований без попередження. Ви можете видалити свій акаунт '
        'будь-коли.',
    'In case of abuse of the service (e.g. circumventing restrictions, '
        'automated mass requests, unlawful content), your account may be '
        'suspended without notice. You can delete your account at any time.',
  );
  String get nutzung7 =>
      _t('7. Änderungen', '7. Изменения', '7. Зміни', '7. Changes');
  String get nutzung7Body => _t(
    'Wir behalten uns vor, diese Nutzungsbedingungen jederzeit zu '
        'aktualisieren. Über wesentliche Änderungen informieren wir in der '
        'App. Letzte Aktualisierung: Juli 2026',
    'Мы оставляем за собой право обновлять эти условия в любое время. О '
        'существенных изменениях мы сообщим в приложении. Последнее '
        'обновление: июль 2026',
    'Ми залишаємо за собою право оновлювати ці умови в будь-який час. Про '
        'суттєві зміни ми повідомимо в застосунку. Останнє оновлення: '
        'липень 2026',
    'We reserve the right to update these terms at any time. We will '
        'announce significant changes in the app. Last updated: July 2026',
  );
  String get nutzung8 =>
      _t('8. Kontakt', '8. Контакт', '8. Контакт', '8. Contact');
}
