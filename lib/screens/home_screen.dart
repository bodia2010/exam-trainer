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
import '../ui/core/theme/exam_theme.dart';
import '../ui/features/home/view_models/home_view_model.dart';
import '../ui/features/startup/startup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.viewModel,
    this.onImportTap,
    this.onCourseTap,
    this.onSpeakingTap,
    this.onFavoritesTap,
    this.showAccountControls = true,
  });

  final HomeViewModel? viewModel;
  final VoidCallback? onImportTap;
  final ValueChanged<ParsedCourse>? onCourseTap;
  final VoidCallback? onSpeakingTap;
  final VoidCallback? onFavoritesTap;
  final bool showAccountControls;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeViewModel _viewModel;
  late final bool _ownsViewModel;
  final _scrollController = ScrollController();
  final _coursesKey = GlobalKey();
  var _startupReadyScheduled = false;

  List<ParsedCourse> get _courses => _viewModel.courses;
  bool get _loading => _viewModel.loading;
  bool get _isPremium => _viewModel.isPremium;

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? HomeViewModel.production();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.start();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    if (_ownsViewModel) _viewModel.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _delete(ParsedCourse course) async {
    await _viewModel.delete(course);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const StartupScreen();
    _scheduleStartupReady();

    final s = S.of(context);
    return Scaffold(
      backgroundColor: ExamColors.canvas,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                ExamSpacing.lg,
                ExamSpacing.md,
                ExamSpacing.lg,
                ExamSpacing.xl,
              ),
              sliver: SliverList.list(
                children: [
                  _buildBrandHeader(s),
                  const SizedBox(height: ExamSpacing.lg),
                  _buildImportBanner(s),
                  if (_viewModel.recentCourse case final course?) ...[
                    const SizedBox(height: ExamSpacing.xl),
                    _SectionTitle(s.weiterlernen),
                    const SizedBox(height: ExamSpacing.sm),
                    _ContinueCourseCard(
                      course: course,
                      variantsLabel: s.variantenCount(_variantCount(course)),
                      actionLabel: s.weiterlernen,
                      onTap: () => _openCourse(course),
                    ),
                  ],
                  const SizedBox(height: ExamSpacing.xl),
                  KeyedSubtree(
                    key: _coursesKey,
                    child: _SectionTitle(
                      s.meineKurse,
                      trailing: _courses.isEmpty
                          ? null
                          : Text(
                              '${_courses.length}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                    ),
                  ),
                  const SizedBox(height: ExamSpacing.sm),
                  if (_courses.isEmpty)
                    _buildEmptyCourses(context, s)
                  else
                    for (final course in _courses) ...[
                      _WarmCourseCard(
                        course: course,
                        subtitle:
                            '${s.ausPdfImportiert} · ${s.variantenCount(_variantCount(course))}',
                        onTap: () => _openCourse(course),
                        onLongPress: () => _confirmDelete(context, course, s),
                      ),
                      const SizedBox(height: ExamSpacing.sm),
                    ],
                  const SizedBox(height: ExamSpacing.lg),
                  _SectionTitle(s.muendlichePruefung),
                  const SizedBox(height: ExamSpacing.sm),
                  _SpeakingPracticeCard(
                    title: s.muendlichePruefung,
                    subtitle: 'B2 Beruf · Teil 1–3',
                    onTap: _openSpeaking,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _WarmBottomNavigation(
        startLabel: s.start,
        coursesLabel: s.kurse,
        favoritesLabel: s.favoriten,
        profileLabel: s.profil,
        onCourses: _scrollToCourses,
        onFavorites: _openFavorites,
        onProfile: () => _openProfile(s),
      ),
    );
  }

  void _scheduleStartupReady() {
    if (_startupReadyScheduled || StartupCoordinator.instance.ready) return;
    _startupReadyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) StartupCoordinator.instance.markReady();
    });
  }

  Widget _buildBrandHeader(S s) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.asset(
            'assets/branding/app_icon.png',
            width: 48,
            height: 48,
          ),
        ),
        const SizedBox(width: ExamSpacing.sm),
        const Expanded(
          child: Text(
            'Exam Trainer',
            style: TextStyle(
              color: ExamColors.ink,
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ),
        if (widget.showAccountControls) ...[
          const _LanguageButton(),
          const SizedBox(width: ExamSpacing.xs),
          _UserAvatarBadge(isPremium: _isPremium, s: s),
        ],
      ],
    );
  }

  Widget _buildImportBanner(S s) {
    return Semantics(
      button: true,
      label: s.pdfImportieren,
      child: InkWell(
        key: const Key('home_import_pdf'),
        onTap: _openImport,
        borderRadius: BorderRadius.circular(ExamRadius.large),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: ExamSpacing.lg,
            vertical: 26,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [ExamColors.teal, Color(0xFF27B6B9)],
            ),
            borderRadius: BorderRadius.circular(ExamRadius.large),
            boxShadow: [
              BoxShadow(
                color: ExamColors.teal.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.file_upload_outlined,
                color: Colors.white,
                size: 30,
              ),
              const SizedBox(width: ExamSpacing.sm),
              Flexible(
                child: Text(
                  s.pdfImportieren,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _variantCount(ParsedCourse course) =>
      course.sections.values.fold(0, (sum, values) => sum + values.length);

  void _openImport() {
    if (widget.onImportTap case final callback?) {
      callback();
    } else {
      context.push('/exam-profile');
    }
  }

  void _openCourse(ParsedCourse course) {
    if (widget.onCourseTap case final callback?) {
      callback(course);
    } else {
      context.push('/course/${course.id}');
    }
  }

  void _openSpeaking() {
    if (widget.onSpeakingTap case final callback?) {
      callback();
    } else {
      context.push('/sprechen');
    }
  }

  void _openFavorites() {
    if (widget.onFavoritesTap case final callback?) {
      callback();
    } else {
      context.push('/favorites');
    }
  }

  void _openProfile(S s) {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    _UserAvatarBadge(
      isPremium: _isPremium,
      s: s,
    ).showAccountInfo(context, user);
  }

  void _scrollToCourses() {
    final coursesContext = _coursesKey.currentContext;
    if (coursesContext == null) return;
    Scrollable.ensureVisible(
      coursesContext,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
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
          const Icon(
            Icons.picture_as_pdf_outlined,
            size: 56,
            color: Color(0xFFBDBDBD),
          ),
          const SizedBox(height: 12),
          Text(
            s.keineKurseImportiert,
            style: const TextStyle(fontSize: 14, color: Color(0xFF757575)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ParsedCourse course, S s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.kursLoeschenTitel),
        content: Text(course.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.abbrechen),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _delete(course);
            },
            child: Text(s.loeschen, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label, {this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?trailing,
      ],
    );
  }
}

class _ContinueCourseCard extends StatelessWidget {
  const _ContinueCourseCard({
    required this.course,
    required this.variantsLabel,
    required this.actionLabel,
    required this.onTap,
  });

  final ParsedCourse course;
  final String variantsLabel;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        key: const Key('home_continue_course'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(ExamRadius.medium),
        child: Padding(
          padding: const EdgeInsets.all(ExamSpacing.md),
          child: Row(
            children: [
              Container(
                width: 78,
                height: 104,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF24B5B6), ExamColors.tealDark],
                  ),
                  borderRadius: BorderRadius.circular(ExamRadius.small),
                ),
                child: Center(
                  child: Text(
                    '${course.examLevel}\n${course.examCourseType}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'serif',
                      fontSize: 18,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: ExamSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${course.examLevel} ${course.examCourseType}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: ExamSpacing.xs),
                    Text(
                      variantsLabel,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: ExamSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onTap,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ExamColors.tealDark,
                          side: const BorderSide(color: ExamColors.teal),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ExamRadius.small,
                            ),
                          ),
                        ),
                        child: Text(actionLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarmCourseCard extends StatelessWidget {
  const _WarmCourseCard({
    required this.course,
    required this.subtitle,
    required this.onTap,
    required this.onLongPress,
  });

  final ParsedCourse course;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(ExamRadius.medium),
        child: Padding(
          padding: const EdgeInsets.all(ExamSpacing.md),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: ExamColors.tealSoft,
                  borderRadius: BorderRadius.circular(ExamRadius.small),
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  color: ExamColors.tealDark,
                  size: 29,
                ),
              ),
              const SizedBox(width: ExamSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: ExamSpacing.xs),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    _CourseSyncBadge(courseId: course.id),
                  ],
                ),
              ),
              const SizedBox(width: ExamSpacing.xs),
              const Icon(
                Icons.chevron_right_rounded,
                color: ExamColors.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Visible cloud-sync outcome for one course (CR-07). Hidden once synced —
/// only worth a line when there is something the user might want to know
/// about (still pending, actively retrying, or stuck after repeated
/// failures).
class _CourseSyncBadge extends StatelessWidget {
  const _CourseSyncBadge({required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ValueListenableBuilder<Map<String, CourseSyncState>>(
      valueListenable: CourseStorage.instance.syncStates,
      builder: (context, states, _) {
        final state = states[courseId] ?? CourseSyncState.synced;
        if (state == CourseSyncState.synced) return const SizedBox.shrink();
        final (icon, color, label) = switch (state) {
          CourseSyncState.pending => (
            Icons.cloud_upload_outlined,
            ExamColors.inkMuted,
            s.syncPending,
          ),
          CourseSyncState.syncing => (
            Icons.cloud_sync_outlined,
            ExamColors.tealDark,
            s.syncSyncing,
          ),
          CourseSyncState.error => (
            Icons.cloud_off_outlined,
            ExamColors.coral,
            s.syncError,
          ),
          CourseSyncState.synced => (
            Icons.cloud_done_outlined,
            ExamColors.tealDark,
            '',
          ),
        };
        final content = Padding(
          padding: const EdgeInsets.only(top: ExamSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: color),
                ),
              ),
            ],
          ),
        );
        if (state != CourseSyncState.error) return content;
        return Tooltip(
          message: s.syncRetryAction,
          child: InkWell(
            key: Key('course-sync-retry-$courseId'),
            onTap: CourseStorage.instance.retrySyncNow,
            borderRadius: BorderRadius.circular(ExamRadius.small),
            child: content,
          ),
        );
      },
    );
  }
}

class _SpeakingPracticeCard extends StatelessWidget {
  const _SpeakingPracticeCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ExamColors.surfaceWarm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ExamRadius.medium),
        side: BorderSide(color: ExamColors.coral.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        key: const Key('home_speaking_practice'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(ExamRadius.medium),
        child: Padding(
          padding: const EdgeInsets.all(ExamSpacing.md),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: ExamColors.coral,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: ExamSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: ExamSpacing.xxs),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: ExamColors.coral),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarmBottomNavigation extends StatelessWidget {
  const _WarmBottomNavigation({
    required this.startLabel,
    required this.coursesLabel,
    required this.favoritesLabel,
    required this.profileLabel,
    required this.onCourses,
    required this.onFavorites,
    required this.onProfile,
  });

  final String startLabel;
  final String coursesLabel;
  final String favoritesLabel;
  final String profileLabel;
  final VoidCallback onCourses;
  final VoidCallback onFavorites;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      key: const Key('home_bottom_navigation'),
      selectedIndex: 0,
      onDestinationSelected: (index) {
        switch (index) {
          case 1:
            onCourses();
          case 2:
            onFavorites();
          case 3:
            onProfile();
        }
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: startLabel,
        ),
        NavigationDestination(
          icon: const Icon(Icons.menu_book_outlined),
          label: coursesLabel,
        ),
        NavigationDestination(
          icon: const Icon(Icons.star_border_rounded),
          label: favoritesLabel,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline_rounded),
          label: profileLabel,
        ),
      ],
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
      onTap: () => showAccountInfo(context, user),
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
                isPremium
                    ? Icons.workspace_premium_rounded
                    : Icons.lock_outline_rounded,
                size: 14,
                color: isPremium ? const Color(0xFFF9A825) : Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showAccountInfo(BuildContext context, User user) {
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
            Text(
              user.displayName ?? user.email ?? '',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (user.displayName != null && user.email != null)
              Text(
                user.email!,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
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
                    isPremium
                        ? Icons.workspace_premium_rounded
                        : Icons.lock_outline_rounded,
                    size: 16,
                    color: isPremium
                        ? const Color(0xFFF9A825)
                        : Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isPremium ? s.premiumKonto : s.kostenlosesKonto,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isPremium
                          ? const Color(0xFFB8860B)
                          : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.privacy_tip_outlined,
                color: Color(0xFF1A237E),
              ),
              title: Text(s.datenschutzerklaerung),
              onTap: () {
                Navigator.pop(context);
                context.push('/privacy-policy');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.description_outlined,
                color: Color(0xFF1A237E),
              ),
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
              leading: const Icon(
                Icons.delete_forever_outlined,
                color: Colors.red,
              ),
              title: Text(
                s.kontoLoeschen,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
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
          context,
          s.kontoLoeschenTeilfehlerTitel,
          s.kontoLoeschenTeilfehler,
        );
        if (!context.mounted) return;
        await AuthService.instance.signOut();
        if (context.mounted) context.go('/login');
        break;
      case AccountDeleteOutcome.failure:
        // Nothing was deleted — account and local data are untouched,
        // stay signed in so the user can simply retry.
        await _showBlockingInfo(
          context,
          s.kontoLoeschenFehlerTitel,
          s.kontoLoeschenFehler,
        );
        break;
    }
  }

  Future<void> _showBlockingInfo(
    BuildContext context,
    String title,
    String message,
  ) {
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

  const _UserPhoto({
    required this.user,
    required this.radius,
    this.fontSize = 16,
  });

  String get _initial =>
      (user.displayName?.isNotEmpty == true
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
      imageBuilder: (context, imageProvider) =>
          CircleAvatar(radius: radius, backgroundImage: imageProvider),
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
        builder: (context, _) {
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
              const Icon(
                Icons.check_rounded,
                color: Color(0xFF1A237E),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
