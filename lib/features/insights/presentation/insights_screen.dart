import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/models/article.dart';
import '../../../data/models/cycle.dart';
import '../../../routing/app_router.dart';
import 'widgets/cycle_length_chart.dart';

enum _Section { stats, articles }

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  _Section _section = _Section.stats;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.bgGrouped,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            backgroundColor: AppColors.glassNavBar,
            largeTitle: const Text('Wawasan'),
            border: const Border(),
            stretch: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, AppSpacing.md),
              child: CupertinoSlidingSegmentedControl<_Section>(
                groupValue: _section,
                backgroundColor: AppColors.fillSubtle,
                thumbColor: AppColors.bgElevated,
                onValueChanged: (s) {
                  if (s != null) {
                    HapticFeedback.selectionClick();
                    setState(() => _section = s);
                  }
                },
                children: {
                  _Section.stats: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Statistik',
                      style: AppTypography.subheadlineEmphasized,
                    ),
                  ),
                  _Section.articles: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Artikel',
                      style: AppTypography.subheadlineEmphasized,
                    ),
                  ),
                },
              ),
            ),
          ),
          if (_section == _Section.stats)
            const _StatsSection()
          else
            const _ArticlesSection(),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

class _StatsSection extends ConsumerWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycles = ref.watch(cyclesProvider).value ?? const [];
    final forecast = ref.watch(todayForecastProvider);

    final lengths = _historicLengths(cycles);
    final periodLengths = cycles
        .where((c) => c.endDate != null)
        .map((c) => c.periodLength)
        .toList();

    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Rata-rata siklus',
                  value: '${forecast.cycleLength}',
                  unit: 'hari',
                  color: AppColors.accentPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  label: 'Rata-rata haid',
                  value: '${forecast.periodLength}',
                  unit: 'hari',
                  color: AppColors.peach,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Keteraturan',
                  value: _regularityLabel(forecast.regularityScore),
                  unit: '',
                  color: AppColors.mint,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  label: 'Total siklus',
                  value: '${cycles.length}',
                  unit: 'tercatat',
                  color: AppColors.lavender,
                ),
              ),
            ],
          ),
        ),
        const SectionHeader(
          title: 'Panjang siklus terakhir',
          subtitle: 'Bar paling kanan adalah siklus terbaru',
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadow.subtle,
          ),
          child: CycleLengthChart(lengths: lengths),
        ),
        if (periodLengths.isNotEmpty) ...[
          const SectionHeader(title: 'Catatan tambahan'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadow.subtle,
            ),
            child: Column(
              children: [
                _ListRow(
                  label: 'Siklus terpendek',
                  value: lengths.isEmpty
                      ? '-'
                      : '${lengths.reduce((a, b) => a < b ? a : b)} hari',
                ),
                _ListRow(
                  label: 'Siklus terpanjang',
                  value: lengths.isEmpty
                      ? '-'
                      : '${lengths.reduce((a, b) => a > b ? a : b)} hari',
                ),
                _ListRow(
                  label: 'Haid terpendek',
                  value:
                      '${periodLengths.reduce((a, b) => a < b ? a : b)} hari',
                ),
                _ListRow(
                  label: 'Haid terpanjang',
                  value:
                      '${periodLengths.reduce((a, b) => a > b ? a : b)} hari',
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ]),
    );
  }

  List<int> _historicLengths(List<Cycle> cycles) {
    final sorted = [...cycles]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final result = <int>[];
    for (var i = 0; i < sorted.length - 1; i++) {
      result.add(
        sorted[i + 1].startDate.difference(sorted[i].startDate).inDays,
      );
    }
    return result.length > 6 ? result.sublist(result.length - 6) : result;
  }

  String _regularityLabel(double score) {
    if (score >= 0.85) return 'Sangat teratur';
    if (score >= 0.6) return 'Teratur';
    if (score >= 0.3) return 'Bervariasi';
    return 'Belum cukup data';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.footnote.copyWith(
              color: AppColors.labelSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // FittedBox auto-scale value supaya teks panjang (mis. "Bervariasi"
          // atau "Sangat teratur") tidak wrap ke baris kedua.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: AppTypography.title1.copyWith(color: color),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: AppTypography.footnote.copyWith(
                        color: AppColors.labelSecondary,
                      ),
                    ),
                ],
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.subheadline.copyWith(
                    color: AppColors.labelSecondary,
                  ),
                ),
              ),
              Text(value, style: AppTypography.subheadlineEmphasized),
            ],
          ),
          if (!isLast) ...[
            const SizedBox(height: 10),
            Container(height: 0.5, color: AppColors.separator),
          ],
        ],
      ),
    );
  }
}

class _ArticlesSection extends ConsumerWidget {
  const _ArticlesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(articleRepositoryProvider);
    return SliverToBoxAdapter(
      child: FutureBuilder<List<Article>>(
        future: repo.all(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CupertinoActivityIndicator()),
            );
          }
          final articles = snap.data!;
          return Column(
            children: [
              for (final a in articles)
                _ArticleCard(
                  article: a,
                  onTap: () => context.goNamed(
                    AppRoute.articleDetail,
                    pathParameters: {'id': a.id},
                  ),
                ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article, required this.onTap});

  final Article article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gradient = (article.gradient ?? ['FFB5C5', 'FFD3DC'])
        .map((h) => Color(int.parse('FF$h', radix: 16)))
        .toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadow.subtle,
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: Text(
                    article.emoji ?? '📖',
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.category.toUpperCase(),
                      style: AppTypography.caption2.copyWith(
                        color: AppColors.accentPrimary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.title,
                      style: AppTypography.subheadlineEmphasized,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${article.readMinutes} menit baca',
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.labelSecondary,
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
