import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_providers.dart';
import '../data/chat_repository.dart';
import '../data/models/chat_message.dart';
import '../data/openrouter_service.dart';

/// Repository provider — butuh UID user saat ini.
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw StateError('Chat diakses sebelum login.');
  return ChatRepository(uid: user.uid);
});

/// Service OpenRouter (stateless singleton).
final openRouterServiceProvider = Provider<OpenRouterService>((ref) {
  return OpenRouterService();
});

/// Stream semua sesi chat user, terbaru di atas.
final chatSessionsProvider = StreamProvider<List<ChatSession>>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchSessions();
});

/// Stream pesan dalam satu sesi chat.
final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((
  ref,
  sessionId,
) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchMessages(sessionId);
});

/// Apakah AI sedang memproses respons.
final chatLoadingProvider = StateProvider<bool>((ref) => false);

/// Kirim pesan user, simpan ke Firestore, panggil AI, simpan balasan.
///
/// Return session ID (berguna kalau buat sesi baru).
Future<String> sendChatMessage(
  WidgetRef ref, {
  required String? sessionId,
  required String userMessage,
}) async {
  final repo = ref.read(chatRepositoryProvider);
  final service = ref.read(openRouterServiceProvider);

  // Buat sesi baru kalau belum ada.
  final sid =
      sessionId ??
      await repo.createSession(
        userMessage.length > 50
            ? '${userMessage.substring(0, 47)}...'
            : userMessage,
      );

  // Simpan pesan user.
  await repo.addMessage(
    sid,
    ChatMessage(
      id: '',
      role: 'user',
      content: userMessage,
      createdAt: DateTime.now(),
    ),
  );

  // Update judul sesi dari pesan pertama user (kalau masih default).
  final currentMsgs = await repo.watchMessages(sid).first;
  final userMsgs = currentMsgs.where((m) => m.role == 'user').toList();
  if (userMsgs.length == 1) {
    final title = userMessage.length > 50
        ? '${userMessage.substring(0, 47)}...'
        : userMessage;
    await repo.updateSession(sid, title: title);
  }

  ref.read(chatLoadingProvider.notifier).state = true;

  try {
    // Ambil semua pesan history untuk konteks.
    final msgs = await repo.watchMessages(sid).first;
    final history = msgs
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    final reply = await service.sendMessages(history);

    // Simpan balasan AI.
    await repo.addMessage(
      sid,
      ChatMessage(
        id: '',
        role: 'assistant',
        content: reply,
        createdAt: DateTime.now(),
      ),
    );
  } finally {
    ref.read(chatLoadingProvider.notifier).state = false;
  }

  return sid;
}
