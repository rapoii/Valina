import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/chat_message.dart';

/// Repository CRUD untuk chat sessions & messages di Firestore.
class ChatRepository {
  ChatRepository({required this.uid, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _sessionsCol =>
      _firestore.collection('users').doc(uid).collection('chatSessions');

  CollectionReference<Map<String, dynamic>> _messagesCol(String sessionId) =>
      _sessionsCol.doc(sessionId).collection('messages');

  // ── Sessions ──────────────────────────────────────────────────

  /// Stream semua sesi, terbaru di atas.
  Stream<List<ChatSession>> watchSessions() {
    return _sessionsCol
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatSession.fromMap(d.id, d.data()))
            .toList());
  }

  /// Buat sesi baru, return ID.
  Future<String> createSession(String title) async {
    final now = DateTime.now();
    final doc = await _sessionsCol.add(ChatSession(
      id: '',
      title: title,
      createdAt: now,
      updatedAt: now,
    ).toMap());
    return doc.id;
  }

  /// Update judul & timestamp sesi.
  Future<void> updateSession(String sessionId, {String? title}) async {
    final updates = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
    if (title != null) updates['title'] = title;
    await _sessionsCol.doc(sessionId).update(updates);
  }

  /// Hapus sesi beserta semua pesan.
  Future<void> deleteSession(String sessionId) async {
    // Hapus subcollection messages dulu.
    final msgs = await _messagesCol(sessionId).get();
    final batch = _firestore.batch();
    for (final doc in msgs.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_sessionsCol.doc(sessionId));
    await batch.commit();
  }

  // ── Messages ──────────────────────────────────────────────────

  /// Stream pesan dalam sesi, urut kronologis.
  Stream<List<ChatMessage>> watchMessages(String sessionId) {
    return _messagesCol(sessionId)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatMessage.fromMap(d.id, d.data()))
            .toList());
  }

  /// Tambah pesan ke sesi.
  Future<void> addMessage(String sessionId, ChatMessage message) async {
    await _messagesCol(sessionId).add(message.toMap());
    await updateSession(sessionId);
  }
}
