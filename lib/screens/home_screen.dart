import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/strings.dart';
import '../models/parsed_course.dart';
import '../services/account_service.dart';
import '../services/auth_service.dart';
import '../services/course_storage.dart';
import '../services/locale_service.dart';
import '../services/parse_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ParsedCourse> _courses = [];
  bool _loading = true;
  bool _isPremium = false;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _load();
    _loadPremiumStatus();
    CourseStorage.instance.revision.addListener(_load);
    // GoRouter can reuse this same Home instance across a sign-out/sign-in
    // (no initState re-run), so without this a second account logging in
    // on the same device would keep showing the previous account's course
    // list and premium status until the app was force-restarted.
    _authSub = AuthService.instance.authStateChanges.listen((_) {
      _load();
      _loadPremiumStatus();
    });
  }

  @override
  void dispose() {
    CourseStorage.instance.revision.removeListener(_load);
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final courses = await CourseStorage.instance.loadAll();
      if (mounted) setState(() { _courses = courses; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _loadPremiumStatus() async {
    final isPremium = await ParseService.instance.isPremium();
    if (mounted) setState(() => _isPremium = isPremium);
  }

  Future<void> _delete(ParsedCourse course) async {
    await CourseStorage.instance.delete(course.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.willkommen,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              const Text('Exam Trainer',
                                  style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1A237E),
                                      letterSpacing: -0.5)),
                            ],
                          ),
                        ),
                        _UserAvatarBadge(isPremium: _isPremium, s: s),
                        const SizedBox(width: 8),
                        const _LanguageButton(),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () => AuthService.instance.signOut(),
                          icon: const Icon(Icons.logout_rounded, color: Color(0xFF6B7280)),
                          tooltip: s.abmelden,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _buildHeroCard(context, s),
                    const SizedBox(height: 28),
                    Text(s.uebungsbereiche,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A237E))),
                    const SizedBox(height: 14),
                    _QuickCard(
                      label: s.muendlichePruefung,
                      subtitle: 'B2 Beruf · Teil 1–3',
                      icon: Icons.record_voice_over_rounded,
                      color: const Color(0xFF6A1B9A),
                      onTap: () => context.push('/sprechen'),
                    ),
                    const SizedBox(height: 10),
                    _QuickCard(
                      label: s.favoriten,
                      subtitle: s.gespeicherteUebungen,
                      icon: Icons.bookmark_rounded,
                      color: const Color(0xFFB8860B),
                      onTap: () => context.push('/favorites'),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Text(s.meineKurse,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A237E))),
                        const Spacer(),
                        if (_courses.isNotEmpty)
                          Text('${_courses.length}',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[600])),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_courses.isEmpty)
                      _buildEmptyCourses(context, s)
                    else
                      _buildCourseList(context, s),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, S s) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(s.eigenesPdf,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                ),
                const SizedBox(height: 16),
                Text(s.pruefungMitEigenemMaterial,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.2)),
                const SizedBox(height: 8),
                Text(s.pdfHochladenHint,
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => context.push('/exam-profile'),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.upload_file, color: Color(0xFF1A237E), size: 18),
                        const SizedBox(width: 8),
                        Text(s.pdfImportieren,
                            style: const TextStyle(
                                color: Color(0xFF1A237E),
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCourses(BuildContext context, S s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.picture_as_pdf_outlined, size: 56, color: Color(0xFFBDBDBD)),
          const SizedBox(height: 12),
          Text(s.keineKurseImportiert,
              style: const TextStyle(fontSize: 14, color: Color(0xFF757575))),
        ],
      ),
    );
  }

  Widget _buildCourseList(BuildContext context, S s) {
    return Column(
      children: [
        for (final course in _courses) ...[
          _QuickCard(
            label: course.title,
            subtitle:
                '${s.variantenCount(course.sections.values.fold(0, (sum, v) => sum + v.length))} · ${_formatDate(course.parsedAt)}',
            icon: Icons.menu_book_rounded,
            color: const Color(0xFF00838F),
            onTap: () => context.push('/course/${course.id}'),
            onLongPress: () => _confirmDelete(context, course, s),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  void _confirmDelete(BuildContext context, ParsedCourse course, S s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.kursLoeschenTitel),
        content: Text(course.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(s.abbrechen)),
          TextButton(
            onPressed: () { Navigator.pop(context); _delete(course); },
            child: Text(s.loeschen, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}

class _QuickCard extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _QuickCard({
    required this.label,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}

class _UserAvatarBadge extends StatelessWidget {
  final bool isPremium;
  final S s;

  const _UserAvatarBadge({required this.isPremium, required this.s});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _showAccountInfo(context, user),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _UserPhoto(user: user, radius: 20),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPremium ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
                size: 14,
                color: isPremium ? const Color(0xFFF9A825) : Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAccountInfo(BuildContext context, User user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _UserPhoto(user: user, radius: 32, fontSize: 24),
            const SizedBox(height: 12),
            Text(user.displayName ?? user.email ?? '',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (user.displayName != null && user.email != null)
              Text(user.email!, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isPremium
                    ? const Color(0xFFF9A825).withValues(alpha: 0.12)
                    : Colors.grey.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPremium ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
                    size: 16,
                    color: isPremium ? const Color(0xFFF9A825) : Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isPremium ? s.premiumKonto : s.kostenlosesKonto,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isPremium ? const Color(0xFFB8860B) : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined,
                  color: Color(0xFF1A237E)),
              title: Text(s.datenschutzerklaerung),
              onTap: () {
                Navigator.pop(context);
                context.push('/privacy-policy');
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.description_outlined, color: Color(0xFF1A237E)),
              title: Text(s.nutzungsbedingungen),
              onTap: () {
                Navigator.pop(context);
                context.push('/terms');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Color(0xFF1A237E)),
              title: Text(s.impressum),
              onTap: () {
                Navigator.pop(context);
                context.push('/impressum');
              },
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
              title: Text(s.kontoLoeschen,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteAccount(context, s);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Destructive, irreversible action — confirmed with an explicit dialog
  // whose copy spells out exactly what gets wiped, before anything happens.
  void _confirmDeleteAccount(BuildContext context, S s) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.kontoLoeschenTitel),
        content: Text(s.kontoLoeschenWarnung),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.abbrechen),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _performDeleteAccount(context, s);
            },
            child: Text(
              s.kontoEndgueltigLoeschen,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteAccount(BuildContext context, S s) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(s.kontoWirdGeloescht)),
          ],
        ),
      ),
    );

    final result = await AccountService.instance.deleteAccount();

    if (!context.mounted) return;
    Navigator.pop(context); // close the "deleting…" dialog

    switch (result.outcome) {
      case AccountDeleteOutcome.success:
        await AuthService.instance.signOut();
        if (context.mounted) context.go('/login');
        break;
      case AccountDeleteOutcome.partialFailure:
        // Data is confirmed gone server-side even though the auth account
        // itself survived — sign out anyway so the client state matches
        // reality (there's nothing left to be signed into, functionally),
        // and tell the user plainly what happened and what to do next.
        await _showBlockingInfo(
            context, s.kontoLoeschenTeilfehlerTitel, s.kontoLoeschenTeilfehler);
        if (!context.mounted) return;
        await AuthService.instance.signOut();
        if (context.mounted) context.go('/login');
        break;
      case AccountDeleteOutcome.failure:
        // Nothing was deleted — account and local data are untouched,
        // stay signed in so the user can simply retry.
        await _showBlockingInfo(context, s.kontoLoeschenFehlerTitel, s.kontoLoeschenFehler);
        break;
    }
  }

  Future<void> _showBlockingInfo(BuildContext context, String title, String message) {
    if (!context.mounted) return Future.value();
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _UserPhoto extends StatelessWidget {
  final User user;
  final double radius;
  final double fontSize;

  const _UserPhoto({required this.user, required this.radius, this.fontSize = 16});

  String get _initial => (user.displayName?.isNotEmpty == true
          ? user.displayName![0]
          : user.email?[0] ?? '?')
      .toUpperCase();

  Widget _fallback() => CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF1A237E),
        child: Text(
          _initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final photoUrl = user.photoURL;
    if (photoUrl == null) return _fallback();

    // Google CDN supports size override — request 200px to avoid CDN cache issues
    final url = photoUrl.contains('googleusercontent.com')
        ? photoUrl.replaceAll(RegExp(r'=s\d+-c$'), '=s200-c')
        : photoUrl;

    return CachedNetworkImage(
      imageUrl: url,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => _fallback(),
      errorWidget: (context, url, error) {
        debugPrint('Avatar load error: $error for $url');
        return _fallback();
      },
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton();

  static const _options = [
    (Locale('de'), '🇩🇪', 'Deutsch'),
    (Locale('en'), '🇬🇧', 'English'),
    (Locale('ru'), '🇷🇺', 'Русский'),
    (Locale('uk'), '🇺🇦', 'Українська'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleService.instance,
      builder: (context, _) {
        final cur = LocaleService.instance.locale;
        final flag = _options
            .firstWhere((o) => o.$1 == cur, orElse: () => _options.first)
            .$2;
        return GestureDetector(
          onTap: () => _showPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(flag, style: const TextStyle(fontSize: 20)),
          ),
        );
      },
    );
  }

  void _showPicker(BuildContext context) {
    final s = S.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ListenableBuilder(
        listenable: LocaleService.instance,
        builder: (context, __) {
          final current = LocaleService.instance.locale;
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  s.sprache,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 16),
                for (final (locale, flag, label) in _LanguageButton._options)
                  _LangTile(
                    flag: flag,
                    label: label,
                    selected: current == locale,
                    onTap: () {
                      LocaleService.instance.setLocale(locale);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangTile({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? const Color(0xFF1A237E) : Colors.black87,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded, color: Color(0xFF1A237E), size: 20),
          ],
        ),
      ),
    );
  }
}
