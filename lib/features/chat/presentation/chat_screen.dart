import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../routing/app_router.dart';
import '../application/chat_providers.dart';
import '../data/models/chat_message.dart';

/// Daftar sesi chat + tombol buat chat baru.
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(chatSessionsProvider);

    return sessionsAsync.when(
      loading: () => CupertinoPageScaffold(
        backgroundColor: AppColors.bgGrouped,
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: const Text('Chat'),
              backgroundColor: AppColors.glassNavBar,
              border: const Border(
                bottom: BorderSide(color: AppColors.separator, width: 0.3),
              ),
            ),
            const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator()),
            ),
          ],
        ),
      ),
      error: (e, _) => CupertinoPageScaffold(
        backgroundColor: AppColors.bgGrouped,
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: const Text('Chat'),
              backgroundColor: AppColors.glassNavBar,
              border: const Border(
                bottom: BorderSide(color: AppColors.separator, width: 0.3),
              ),
            ),
            SliverFillRemaining(child: Center(child: Text('Error: $e'))),
          ],
        ),
      ),
      data: (sessions) {
        // ── Empty state: 2-header tapi tidak bisa scroll ──
        if (sessions.isEmpty) {
          return CupertinoPageScaffold(
            backgroundColor: AppColors.bgGrouped,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                CupertinoSliverNavigationBar(
                  largeTitle: const Text('Chat'),
                  backgroundColor: AppColors.glassNavBar,
                  border: const Border(
                    bottom: BorderSide(color: AppColors.separator, width: 0.3),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.chat_bubble_2,
                            size: 56,
                            color: AppColors.labelTertiary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Belum ada percakapan',
                            style: AppTypography.headline.copyWith(
                              color: AppColors.labelSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Mulai chat baru dengan Valina AI\nuntuk tanya seputar kesehatan reproduksi',
                            textAlign: TextAlign.center,
                            style: AppTypography.subheadline.copyWith(
                              color: AppColors.labelTertiary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          CupertinoButton.filled(
                            onPressed: () => _createNewChat(context, ref),
                            child: const Text('Chat Baru'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // ── Ada sesi: 2-header (large title + collapsed) + floating + button ──
        return CupertinoPageScaffold(
          backgroundColor: AppColors.bgGrouped,
          child: Stack(
            children: [
              CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  CupertinoSliverNavigationBar(
                    largeTitle: const Text('Chat'),
                    backgroundColor: AppColors.glassNavBar,
                    border: const Border(
                      bottom: BorderSide(
                        color: AppColors.separator,
                        width: 0.3,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _SessionTile(
                          session: sessions[index],
                          onTap: () => context.go(
                            '${AppRoute.chat}/${sessions[index].id}',
                          ),
                          onDelete: () =>
                              _deleteSession(context, ref, sessions[index]),
                        ),
                        childCount: sessions.length,
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 20,
                bottom: 90,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _createNewChat(context, ref),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppShadow.raised,
                    ),
                    child: const Center(
                      child: Icon(
                        CupertinoIcons.plus,
                        size: 26,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createNewChat(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    final repo = ref.read(chatRepositoryProvider);
    final sessionId = await repo.createSession('Chat Baru');
    if (context.mounted) {
      context.go('${AppRoute.chat}/$sessionId');
    }
  }

  Future<void> _deleteSession(
    BuildContext context,
    WidgetRef ref,
    ChatSession session,
  ) async {
    HapticFeedback.heavyImpact();
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Hapus percakapan?'),
        content: const Text('Semua pesan dalam percakapan ini akan dihapus.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(chatRepositoryProvider).deleteSession(session.id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  final ChatSession session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final timeAgo = _formatTime(session.updatedAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadow.subtle,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accentSoft,
                      AppColors.accentPrimary.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    CupertinoIcons.chat_bubble_fill,
                    size: 18,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: AppTypography.headline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeAgo,
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.labelSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(32, 32),
                onPressed: onDelete,
                child: const Icon(
                  CupertinoIcons.delete,
                  size: 18,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
