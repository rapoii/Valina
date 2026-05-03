import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/cycle.dart';
import '../data/models/day_log.dart';
import '../data/models/enums.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/article_repository.dart';
import '../data/repositories/cycle_repository.dart';
import '../data/repositories/log_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../features/auth/application/auth_providers.dart';
import 'utils/cycle_calculator.dart';
import 'utils/date_x.dart';

// =============================================================
// UID accessors
// =============================================================
/// UID user saat ini. Throws kalau dipanggil saat belum login.
///
/// Repository provider hanya boleh di-`read`/`watch` setelah dipastikan ada
/// user, biasanya dari dalam stream provider yang sudah short-circuit lebih
/// dulu, atau dari handler aksi (button, dll) di screen yang dijaga router.
final _currentUidProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw StateError(
      'Provider yang butuh data Firestore dipanggil sebelum user login.',
    );
  }
  return user.uid;
});

/// UID "efektif" untuk baca data siklus/log/forecast.
///
/// - Untuk **female** (atau yang belum onboarding): return own uid.
/// - Untuk **male** yang sudah link ke pasangan: return `partnerUid` — supaya
///   semua screen otomatis memperlihatkan data si cewek, read-only.
///
/// Writes **tidak boleh** pakai uid ini — selalu pakai own uid via
/// `profileRepositoryProvider` / `cycleRepositoryProvider` / `logRepositoryProvider`.
final effectiveUidProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  // Tonton profile OWN user (bukan yang effective) — kita butuh gender + partnerUid-nya.
  final ownProfile = ref.watch(ownProfileProvider).value;
  if (ownProfile == null) return user.uid;
  if (ownProfile.gender == UserGender.male) {
    final linkedUid = ownProfile.partnerUid;
    if (linkedUid != null && linkedUid.isNotEmpty) {
      return linkedUid;
    }
    // Male tapi belum link — return null agar UI tahu harus redirect ke onboarding.
    return null;
  }
  return user.uid;
});

// =============================================================
// Repositories (WRITES — selalu target own uid)
// =============================================================
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final uid = ref.watch(_currentUidProvider);
  return ProfileRepository(uid: uid);
});

final cycleRepositoryProvider = Provider<CycleRepository>((ref) {
  final uid = ref.watch(_currentUidProvider);
  return CycleRepository(uid: uid);
});

final logRepositoryProvider = Provider<LogRepository>((ref) {
  final uid = ref.watch(_currentUidProvider);
  return LogRepository(uid: uid);
});

final articleRepositoryProvider = Provider<ArticleRepository>((ref) {
  final uid = ref.watch(_currentUidProvider);
  return ArticleRepository(uid: uid);
});

// =============================================================
// Reactive state (Firestore streams)
//
// Semua stream provider di bawah short-circuit kalau user belum login —
// mengembalikan empty/null — supaya screen yang sempat dibangun saat router
// transisi ke /login tidak crash.
// =============================================================

/// Profile OWN user — selalu profile milik login user ini.
/// Dipakai oleh Profile screen, gender check, dan partner settings.
final ownProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream<UserProfile?>.value(null);
  final repo = ProfileRepository(uid: user.uid);
  return repo.watch();
});

/// Profile EFEKTIF — partner's profile kalau male+linked, else own profile.
/// Dipakai Today/Calendar/Insights untuk kalkulasi siklus.
final profileProvider = StreamProvider<UserProfile?>((ref) {
  final effectiveUid = ref.watch(effectiveUidProvider);
  if (effectiveUid == null) return Stream<UserProfile?>.value(null);
  final repo = ProfileRepository(uid: effectiveUid);
  return repo.watch();
});

/// Semua siklus EFEKTIF (partner's kalau male+linked), tersortir terbaru.
final cyclesProvider = StreamProvider<List<Cycle>>((ref) {
  final effectiveUid = ref.watch(effectiveUidProvider);
  if (effectiveUid == null) return Stream<List<Cycle>>.value(const []);
  final repo = CycleRepository(uid: effectiveUid);
  return repo.watchAll();
});

/// Semua day logs EFEKTIF reactive.
final allLogsProvider = StreamProvider<List<DayLog>>((ref) {
  final effectiveUid = ref.watch(effectiveUidProvider);
  if (effectiveUid == null) return Stream<List<DayLog>>.value(const []);
  final repo = LogRepository(uid: effectiveUid);
  return repo.watchAll();
});

/// Log EFEKTIF untuk satu tanggal tertentu.
final logForDateProvider = StreamProvider.family<DayLog, DateTime>((ref, date) {
  final effectiveUid = ref.watch(effectiveUidProvider);
  if (effectiveUid == null) {
    return Stream<DayLog>.value(DayLog(date: date.dateOnly));
  }
  final repo = LogRepository(uid: effectiveUid);
  return repo.watchDate(date);
});

/// Bookmark artikel — selalu OWN user (personal preference, tidak di-share).
final bookmarksProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream<Set<String>>.value(const {});
  final repo = ref.watch(articleRepositoryProvider);
  return repo.watchBookmarks();
});

/// Forecast siklus untuk hari ini (re-compute saat data berubah).
final todayForecastProvider = Provider<CycleForecast>((ref) {
  final cycles = ref.watch(cyclesProvider).value ?? const [];
  final profile = ref.watch(profileProvider).value;
  return CycleCalculator.compute(
    cycles: cycles,
    fallbackCycleLength: profile?.avgCycleLength ?? 28,
    fallbackPeriodLength: profile?.avgPeriodLength ?? 5,
    today: DateTime.now().dateOnly,
  );
});

/// Forecast untuk tanggal arbitrer — cached & autoDispose untuk efisiensi memori.
final forecastForDateProvider = Provider.autoDispose
    .family<CycleForecast, DateTime>((ref, date) {
      final cycles = ref.watch(cyclesProvider).value ?? const [];
      final profile = ref.watch(profileProvider).value;
      // keepAlive memastikan provider tetap hidup selama data tidak berubah
      ref.keepAlive();
      return CycleCalculator.compute(
        cycles: cycles,
        fallbackCycleLength: profile?.avgCycleLength ?? 28,
        fallbackPeriodLength: profile?.avgPeriodLength ?? 5,
        today: date.dateOnly,
      );
    });

// =============================================================
// Partner / read-only flags (derived)
// =============================================================

/// Apakah user saat ini male (read-only mode)?
final isReadOnlyProvider = Provider<bool>((ref) {
  final ownProfile = ref.watch(ownProfileProvider).value;
  return ownProfile?.gender == UserGender.male;
});

/// Apakah user saat ini boleh lihat fase siklus & prediksi? (Male perlu sharePhase dari partner.)
final canViewPhaseProvider = Provider<bool>((ref) {
  final ownProfile = ref.watch(ownProfileProvider).value;
  if (ownProfile == null) return true;
  if (ownProfile.gender != UserGender.male) return true;
  final partner = ref.watch(profileProvider).value;
  return partner?.sharePhase ?? false;
});

/// Apakah user saat ini boleh lihat log harian (flow/mood/symptom)?
final canViewLogsProvider = Provider<bool>((ref) {
  final ownProfile = ref.watch(ownProfileProvider).value;
  if (ownProfile == null) return true;
  if (ownProfile.gender != UserGender.male) return true;
  final partner = ref.watch(profileProvider).value;
  return partner?.shareLogs ?? false;
});

/// Apakah user saat ini boleh lihat catatan pribadi?
final canViewNotesProvider = Provider<bool>((ref) {
  final ownProfile = ref.watch(ownProfileProvider).value;
  if (ownProfile == null) return true;
  if (ownProfile.gender != UserGender.male) return true;
  final partner = ref.watch(profileProvider).value;
  return partner?.shareNotes ?? false;
});
