import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/chat_message.dart';

/// Bubble pesan chat — kiri untuk AI, kanan untuk user.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 60 : 16,
        right: isUser ? 16 : 60,
        top: 4,
        bottom: 4,
      ),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isUser ? AppColors.accentSoft : AppColors.bgElevated,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.systemGrey.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: isUser
              ? Text(
                  message.content,
                  style: AppTypography.body.copyWith(
                    color: AppColors.accentPressed,
                  ),
                )
              : MarkdownBody(
                  data: message.content,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: AppTypography.body.copyWith(
                      color: AppColors.labelPrimary,
                    ),
                    strong: AppTypography.body.copyWith(
                      color: AppColors.labelPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    listBullet: AppTypography.body.copyWith(
                      color: AppColors.labelPrimary,
                    ),
                    h1: AppTypography.title2.copyWith(
                      color: AppColors.labelPrimary,
                    ),
                    h2: AppTypography.headline.copyWith(
                      color: AppColors.labelPrimary,
                    ),
                    h3: AppTypography.headline.copyWith(
                      color: AppColors.labelPrimary,
                    ),
                    blockSpacing: 8,
                  ),
                ),
        ),
      ),
    );
  }
}
