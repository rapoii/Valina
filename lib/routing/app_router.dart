import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../data/models/enums.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/insights/presentation/article_detail_screen.dart';
import '../features/insights/presentation/insights_screen.dart';
import '../features/onboarding/presentation/onboarding_flow.dart';
import '../features/profile/presentation/about_screen.dart';
import '../features/profile/presentation/cycle_settings_screen.dart';
import '../features/profile/presentation/notifications_settings_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/today/presentation/today_screen.dart';
import 'main_shell.dart';

/// Route names untuk navigasi yang aman.
abstract final class AppRoute {
  static const login = '/login';
  static const signup = '/signup';
  static const onboarding = '/onboarding';
  static const today = '/today';
  static const calendar = '/calendar';
  static const insights = '/insights';
  static const profile = '/profile';

  static const articleDetail = 'article-detail';
  static const cycleSettings = 'cycle-settings';
  static const notificationsSettings = 'notifications-settings';
  static const about = 'about';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // Trigger redirect re-evaluation saat auth state ATAU OWN profile berubah.
  //
  // Penting: pakai `ownProfileProvider` (bukan `profileProvider` yang efektif)
  // supaya gender check & onboarding completion bisa dievaluasi dari profile
  // OWN user, bukan dari profile pasangan yang ditampilkan ke male.
  final notifier = _RouterRefreshNotifier();
  ref.listen(authStateProvider, (_, _) => notifier.notify());
  ref.listen(ownProfileProvider, (_, _) => notifier.notify());

  return GoRouter(
    initialLocation: AppRoute.today,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authValue = ref.read(authStateProvider);
      // Tunggu sampai auth state pertama tersedia (hindari flicker).
      if (authValue.isLoading) return null;
      final user = authValue.value;
      final loggedIn = user != null;
      final loc = state.matchedLocation;
      final atLogin = loc == AppRoute.login || loc == AppRoute.signup;

      // Belum login — paksa ke /login (kecuali sudah di halaman auth).
      if (!loggedIn) {
        return atLogin ? null : AppRoute.login;
      }

      // Sudah login tapi masih di halaman auth — redirect ke app.
      if (atLogin) return AppRoute.today;

      // Cek apakah OWN profile sudah di-set (onboarding selesai).
      // Saat `isLoading` true (initial load atau refresh setelah login baru),
      // jangan redirect — tunggu data fresh dari Firestore.
      final profileAsync = ref.read(ownProfileProvider);
      if (profileAsync.isLoading) return null;
      final profile = profileAsync.value;
      final hasProfile = profile != null;
      final atOnboarding = loc == AppRoute.onboarding;

      // Male yang sudah onboarding tapi `partnerUid` null — perlu relink
      // (mis. baru revoke dari sisi sendiri, atau female revoke duluan).
      // Treat sebagai "butuh onboarding lagi" (step partner code saja).
      final maleNeedsPartner =
          hasProfile &&
          profile.gender == UserGender.male &&
          (profile.partnerUid == null || profile.partnerUid!.isEmpty);

      // Belum ada profile ATAU male butuh relink — paksa ke /onboarding.
      if ((!hasProfile || maleNeedsPartner) && !atOnboarding) {
        return AppRoute.onboarding;
      }

      // Sudah lengkap (punya profile & tidak butuh relink) tapi masih di
      // /onboarding — kick ke /today. Kondisi ini HARUS di-check setelah
      // `maleNeedsPartner` supaya male yg baru revoke tidak ter-loop antara
      // /today (ditendang ke /onboarding) dan /onboarding (ditendang ke /today).
      if (hasProfile && !maleNeedsPartner && atOnboarding) {
        return AppRoute.today;
      }

      // Male tidak boleh akses cycle settings (write-only screen untuk female).
      if (hasProfile &&
          profile.gender == UserGender.male &&
          loc.contains('/cycle')) {
        return AppRoute.profile;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoute.login,
        pageBuilder: (context, state) =>
            const CupertinoPage<void>(child: LoginScreen()),
      ),
      GoRoute(
        path: AppRoute.signup,
        pageBuilder: (context, state) =>
            const CupertinoPage<void>(child: SignupScreen()),
      ),
      GoRoute(
        path: AppRoute.onboarding,
        pageBuilder: (context, state) =>
            const CupertinoPage<void>(child: OnboardingFlow()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.today,
                pageBuilder: (context, state) =>
                    const CupertinoPage<void>(child: TodayScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.calendar,
                pageBuilder: (context, state) =>
                    const CupertinoPage<void>(child: CalendarScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.insights,
                pageBuilder: (context, state) =>
                    const CupertinoPage<void>(child: InsightsScreen()),
                routes: [
                  GoRoute(
                    name: AppRoute.articleDetail,
                    path: 'article/:id',
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return CupertinoPage<void>(
                        child: ArticleDetailScreen(articleId: id),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.profile,
                pageBuilder: (context, state) =>
                    const CupertinoPage<void>(child: ProfileScreen()),
                routes: [
                  GoRoute(
                    name: AppRoute.cycleSettings,
                    path: 'cycle',
                    pageBuilder: (context, state) =>
                        const CupertinoPage<void>(child: CycleSettingsScreen()),
                  ),
                  GoRoute(
                    name: AppRoute.notificationsSettings,
                    path: 'notifications',
                    pageBuilder: (context, state) => const CupertinoPage<void>(
                      child: NotificationsSettingsScreen(),
                    ),
                  ),
                  GoRoute(
                    name: AppRoute.about,
                    path: 'about',
                    pageBuilder: (context, state) =>
                        const CupertinoPage<void>(child: AboutScreen()),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Adapter `ChangeNotifier` untuk `GoRouter.refreshListenable`.
class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
