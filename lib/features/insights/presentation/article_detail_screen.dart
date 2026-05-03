import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/article.dart';

class ArticleDetailScreen extends ConsumerStatefulWidget {
  const ArticleDetailScreen({super.key, required this.articleId});

  final String articleId;

  @override
  ConsumerState<ArticleDetailScreen> createState() =>
      _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends ConsumerState<ArticleDetailScreen> {
  Article? _article;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(articleRepositoryProvider);
    final article = await repo.byId(widget.articleId);
    if (!mounted) return;
    setState(() {
      _article = article;
    });
  }

  Future<void> _toggleBookmark() async {
    HapticFeedback.lightImpact();
    await ref.read(articleRepositoryProvider).toggleBookmark(widget.articleId);
    // State otomatis update lewat `bookmarksProvider`.
  }

  @override
  Widget build(BuildContext context) {
    final article = _article;
    if (article == null) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    final gradient = (article.gradient ?? ['FFB5C5', 'FFD3DC'])
        .map((h) => Color(int.parse('FF$h', radix: 16)))
        .toList();

    final bookmarks = ref.watch(bookmarksProvider).value ?? const <String>{};
    final bookmarked = bookmarks.contains(widget.articleId);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.bgGrouped,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.glassNavBar,
        border: const Border(
          bottom: BorderSide(color: AppColors.separator, width: 0.3),
        ),
        middle: Text(article.category, style: AppTypography.headline),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _toggleBookmark,
          child: Icon(
            bookmarked ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
            color: AppColors.accentPrimary,
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Center(
                child: Text(
                  article.emoji ?? '📖',
                  style: const TextStyle(fontSize: 88),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(article.title, style: AppTypography.title1),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${article.readMinutes} menit baca • ${article.category}',
              style: AppTypography.footnote,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              article.summary,
              style: AppTypography.callout.copyWith(
                color: AppColors.labelSecondary,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ..._renderBody(article.body),
          ],
        ),
      ),
    );
  }

  /// Render markdown ringan: heading "## ", bullet "- ".
  List<Widget> _renderBody(String body) {
    final widgets = <Widget>[];
    final lines = body.split('\n');
    for (final line in lines) {
      final trimmed = line.trimRight();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 12));
        continue;
      }
      if (trimmed.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(trimmed.substring(3), style: AppTypography.title3),
          ),
        );
      } else if (trimmed.startsWith('- ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8, right: 10),
                  child: Icon(
                    CupertinoIcons.circle_fill,
                    size: 5,
                    color: AppColors.accentPrimary,
                  ),
                ),
                Expanded(
                  child: Text(
                    trimmed.substring(2),
                    style: AppTypography.body.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _BoldFormattedText(text: trimmed),
          ),
        );
      }
    }
    return widgets;
  }
}

/// Render teks dengan dukungan **bold**.
class _BoldFormattedText extends StatelessWidget {
  const _BoldFormattedText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    var cursor = 0;
    for (final m in regex.allMatches(text)) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, m.start)));
      }
      spans.add(
        TextSpan(
          text: m.group(1),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
      cursor = m.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return Text.rich(
      TextSpan(
        style: AppTypography.body.copyWith(height: 1.55),
        children: spans,
      ),
    );
  }
}
