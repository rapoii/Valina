import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../application/chat_providers.dart';
import 'widgets/chat_bubble.dart';

/// Halaman percakapan tunggal dengan AI.
class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    HapticFeedback.lightImpact();

    try {
      await sendChatMessage(
        ref,
        sessionId: widget.sessionId,
        userMessage: text,
      );
    } catch (e) {
      if (!mounted) return;
      showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Gagal mengirim'),
          content: Text('$e'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.sessionId));
    final isLoading = ref.watch(chatLoadingProvider);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    // Tab bar tingginya ~80px (icon 26 + label 10 + padding 8+6 + bottomPadding).
    // Karena ChatDetailScreen ada di dalam StatefulShellRoute, tab bar overlay
    // di atas konten. Tambahkan offset supaya input bar tidak tertutup.
    const tabBarHeight = 70.0;

    // Auto-scroll saat ada pesan baru.
    ref.listen(chatMessagesProvider(widget.sessionId), (_, _) {
      _scrollToBottom();
    });

    return CupertinoPageScaffold(
      backgroundColor: AppColors.bgGrouped,
      navigationBar: CupertinoNavigationBar(
        middle: Text('Valina AI', style: AppTypography.headline),
        backgroundColor: AppColors.glassNavBar,
        border: const Border(
          bottom: BorderSide(color: AppColors.separator, width: 0.3),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Daftar pesan.
            Expanded(
              child: messagesAsync.when(
                loading: () =>
                    const Center(child: CupertinoActivityIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.chat_bubble_2,
                              size: 48,
                              color: AppColors.labelTertiary,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Tanya apa saja seputar\nkesehatan reproduksi 😊',
                              textAlign: TextAlign.center,
                              style: AppTypography.subheadline.copyWith(
                                color: AppColors.labelSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(0, 8, 0, 8 + bottomPadding),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => ChatBubble(message: messages[i]),
                  );
                },
              ),
            ),

            // Typing indicator.
            if (isLoading)
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CupertinoActivityIndicator(radius: 8),
                      const SizedBox(width: 8),
                      Text(
                        'Valina sedang mengetik...',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.labelSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Input bar.
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.glassNavBar,
                    border: const Border(
                      top: BorderSide(color: AppColors.separator, width: 0.3),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    12,
                    8,
                    8,
                    bottomPadding + tabBarHeight,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoTextField(
                          controller: _controller,
                          placeholder: 'Ketik pesanmu...',
                          maxLines: 4,
                          minLines: 1,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          style: AppTypography.body,
                          decoration: BoxDecoration(
                            color: AppColors.bgElevated,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: AppColors.separator,
                              width: 0.5,
                            ),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      CupertinoButton(
                        padding: const EdgeInsets.all(8),
                        onPressed: isLoading ? null : _send,
                        child: Icon(
                          CupertinoIcons.arrow_up_circle_fill,
                          size: 32,
                          color: isLoading
                              ? AppColors.labelTertiary
                              : AppColors.accentPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
