import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/user_profile.dart';
import '../../../features/auth/application/auth_providers.dart';
import '../../../features/partner/application/partner_providers.dart';
import '../../../features/partner/data/partner_repository.dart';
import '../../../routing/app_router.dart';
import 'steps/cycle_length_step.dart';
import 'steps/dob_step.dart';
import 'steps/gender_step.dart';
import 'steps/goal_step.dart';
import 'steps/last_period_step.dart';
import 'steps/name_step.dart';
import 'steps/partner_code_step.dart';
import 'steps/period_length_step.dart';
import 'steps/welcome_step.dart';

/// State sementara yang diisi selama onboarding.
class OnboardingDraft {
  String name = '';
  UserGender? gender;
  DateTime? dateOfBirth;
  DateTime? lastPeriodDate;
  int avgCycleLength = 28;
  int avgPeriodLength = 5;
  CycleGoal goal = CycleGoal.trackCycle;
  String partnerCode = '';
}

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final _controller = PageController();
  final _draft = OnboardingDraft();
  int _index = 0;
  bool _submitting = false;
  String? _linkError;

  /// True kalau masuk mode "relink" — male yg sudah onboarding tapi baru
  /// revoke (dari sisi sendiri atau female). Skip semua step kecuali input
  /// kode pasangan.
  bool _isRelinkMode() {
    final own = ref.read(ownProfileProvider).value;
    return own != null &&
        own.gender == UserGender.male &&
        (own.partnerUid == null || own.partnerUid!.isEmpty);
  }

  /// Step IDs in order. Daftar aktif tergantung gender yang dipilih:
  /// - Relink mode (male revoke): [partnerCode]
  /// - Belum pilih gender: [welcome, gender]
  /// - Female: [welcome, gender, name, dob, lastPeriod, cycleLen, periodLen, goal]
  /// - Male:   [welcome, gender, name, partnerCode]
  List<_StepId> get _steps {
    if (_isRelinkMode()) return const [_StepId.partnerCode];
    final g = _draft.gender;
    if (g == null) return const [_StepId.welcome, _StepId.gender];
    if (g == UserGender.female) {
      return const [
        _StepId.welcome,
        _StepId.gender,
        _StepId.name,
        _StepId.dob,
        _StepId.lastPeriod,
        _StepId.cycleLen,
        _StepId.periodLen,
        _StepId.goal,
      ];
    }
    return const [
      _StepId.welcome,
      _StepId.gender,
      _StepId.name,
      _StepId.partnerCode,
    ];
  }

  int get _stepCount => _steps.length;

  _StepId get _currentStep => _steps[_index];

  void _next() {
    Haptics.light();
    if (_index >= _stepCount - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    if (_index == 0) return;
    Haptics.selection();
    _controller.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final repo = ref.read(profileRepositoryProvider);
      final cycleRepo = ref.read(cycleRepositoryProvider);
      final user = ref.read(currentUserProvider);
      final existingProfile = ref.read(ownProfileProvider).value;
      final isRelink = _isRelinkMode() && existingProfile != null;
      final gender = isRelink
          ? UserGender.male
          : (_draft.gender ?? UserGender.female);

      if (gender == UserGender.male) {
        // Male flow: link ke partner dulu SEBELUM simpan profile — kalau gagal,
        // user bisa coba kode lain tanpa bikin setengah-setengah state.
        final partnerRepo = ref.read(partnerRepositoryProvider);
        if (user == null) {
          throw const PartnerException('Sesi login hilang. Coba login ulang.');
        }
        final maleName = isRelink
            ? existingProfile.name
            : (_draft.name.trim().isEmpty ? 'Sahabat' : _draft.name.trim());
        final maleEmail = isRelink ? existingProfile.email : user.email;

        String partnerUid;
        try {
          partnerUid = await partnerRepo.linkMaleToCode(
            maleUid: user.uid,
            rawCode: _draft.partnerCode,
            maleName: maleName,
            maleEmail: maleEmail,
          );
        } on PartnerException catch (e) {
          setState(() {
            _submitting = false;
            _linkError = e.message;
          });
          return;
        }

        if (isRelink) {
          // Relink: hanya update field partnerUid di profile yg sudah ada,
          // jangan overwrite field lain (reminder, privacy, dll).
          existingProfile.partnerUid = partnerUid;
          await repo.save(existingProfile);
        } else {
          final profile = UserProfile(
            name: maleName,
            email: maleEmail,
            gender: UserGender.male,
            partnerUid: partnerUid,
            createdAt: DateTime.now(),
          );
          await repo.save(profile);
        }
      } else {
        // Female flow: seperti sebelumnya. (gender default = female)
        final profile = UserProfile(
          name: _draft.name.trim().isEmpty ? 'Sahabat' : _draft.name.trim(),
          email: user?.email,
          dateOfBirth: _draft.dateOfBirth,
          lastPeriodDate: _draft.lastPeriodDate,
          avgCycleLength: _draft.avgCycleLength,
          avgPeriodLength: _draft.avgPeriodLength,
          goal: _draft.goal,
          createdAt: DateTime.now(),
        );
        await repo.save(profile);

        if (_draft.lastPeriodDate != null) {
          await cycleRepo.create(
            startDate: _draft.lastPeriodDate!,
            endDate: _draft.lastPeriodDate!.add(
              Duration(days: _draft.avgPeriodLength - 1),
            ),
          );
        }
      }

      HapticFeedback.mediumImpact();
      if (!mounted) return;
      context.go(AppRoute.today);
    } finally {
      if (mounted && _submitting) {
        setState(() => _submitting = false);
      }
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case _StepId.welcome:
        return true;
      case _StepId.gender:
        return _draft.gender != null;
      case _StepId.name:
        return _draft.name.trim().isNotEmpty;
      case _StepId.dob:
        return _draft.dateOfBirth != null;
      case _StepId.lastPeriod:
        return _draft.lastPeriodDate != null;
      case _StepId.cycleLen:
        return true;
      case _StepId.periodLen:
        return true;
      case _StepId.goal:
        return true;
      case _StepId.partnerCode:
        return _draft.partnerCode.length == 8;
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final relink = _isRelinkMode();
    // Welcome step (index 0 di flow normal) punya tombol sendiri, jadi footer
    // submit button di-hide. Tapi di relink mode, step 0 adalah partnerCode
    // yg BUTUH tombol submit — jadi footer harus tampil walaupun _index == 0.
    final showFooterButton = _index != 0 || relink;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.bgPrimary,
      child: SafeArea(
        child: Column(
          children: [
            _Header(
              index: _index,
              total: _stepCount,
              onBack: _index == 0 ? null : _back,
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: steps.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _buildStep(steps[i]),
              ),
            ),
            if (_linkError != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _linkError!,
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (showFooterButton)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: PrimaryButton(
                  label: _submitting
                      ? 'Menghubungkan...'
                      : (_index == _stepCount - 1 ? 'Selesai' : 'Lanjut'),
                  onPressed: _submitting || !_canProceed() ? null : _next,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(_StepId id) {
    switch (id) {
      case _StepId.welcome:
        return WelcomeStep(onNext: _next);
      case _StepId.gender:
        return GenderStep(
          initial: _draft.gender,
          onChanged: (v) => setState(() => _draft.gender = v),
        );
      case _StepId.name:
        return NameStep(
          initial: _draft.name,
          onChanged: (v) => setState(() => _draft.name = v),
        );
      case _StepId.dob:
        return DobStep(
          initial: _draft.dateOfBirth,
          onChanged: (v) => setState(() => _draft.dateOfBirth = v),
        );
      case _StepId.lastPeriod:
        return LastPeriodStep(
          initial: _draft.lastPeriodDate,
          onChanged: (v) => setState(() => _draft.lastPeriodDate = v),
        );
      case _StepId.cycleLen:
        return CycleLengthStep(
          initial: _draft.avgCycleLength,
          onChanged: (v) => setState(() => _draft.avgCycleLength = v),
        );
      case _StepId.periodLen:
        return PeriodLengthStep(
          initial: _draft.avgPeriodLength,
          onChanged: (v) => setState(() => _draft.avgPeriodLength = v),
        );
      case _StepId.goal:
        return GoalStep(
          initial: _draft.goal,
          onChanged: (v) => setState(() => _draft.goal = v),
        );
      case _StepId.partnerCode:
        return PartnerCodeStep(
          initial: _draft.partnerCode,
          onChanged: (v) => setState(() {
            _draft.partnerCode = v;
            _linkError = null;
          }),
        );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

enum _StepId {
  welcome,
  gender,
  name,
  dob,
  lastPeriod,
  cycleLen,
  periodLen,
  goal,
  partnerCode,
}

class _Header extends StatelessWidget {
  const _Header({
    required this.index,
    required this.total,
    required this.onBack,
  });

  final int index;
  final int total;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: onBack == null
                ? null
                : CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: onBack,
                    child: const Icon(
                      CupertinoIcons.chevron_back,
                      color: AppColors.labelPrimary,
                    ),
                  ),
          ),
          Expanded(
            child: index == 0
                ? const SizedBox.shrink()
                : _ProgressBar(value: (index) / (total - 1)),
          ),
          SizedBox(
            width: 44,
            child: index == 0
                ? null
                : Center(
                    child: Text(
                      '$index/${total - 1}',
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.labelSecondary,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: SizedBox(
        height: 4,
        child: Stack(
          children: [
            Container(color: AppColors.fillSubtle),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                color: AppColors.accentPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
