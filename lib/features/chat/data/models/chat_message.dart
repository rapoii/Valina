import 'package:cloud_firestore/cloud_firestore.dart';

/// Sesi percakapan chat AI.
class ChatSession {
  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        'title': title,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory ChatSession.fromMap(String id, Map<String, dynamic> map) {
    return ChatSession(
      id: id,
      title: (map['title'] as String?) ?? 'Chat',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Pesan tunggal dalam sesi chat.
class ChatMessage {
  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String id;

  /// "user" atau "assistant"
  final String role;
  final String content;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'role': role,
        'content': content,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessage(
      id: id,
      role: (map['role'] as String?) ?? 'user',
      content: (map['content'] as String?) ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
