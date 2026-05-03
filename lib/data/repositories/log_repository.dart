import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/date_x.dart';
import '../models/day_log.dart';

/// Repository log harian, disimpan di Firestore di
/// `users/{uid}/logs/{yyyy-MM-dd}`.
class LogRepository {
  LogRepository({required this.uid, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('users').doc(uid).collection('logs');

  /// Stream semua log.
  Stream<List<DayLog>> watchAll() {
    return _col.snapshots().map((snap) {
      return snap.docs.map((d) => DayLog.fromMap(d.data())).toList();
    });
  }

  /// Stream log untuk satu tanggal. Emit empty `DayLog` saat dokumen belum ada.
  Stream<DayLog> watchDate(DateTime date) {
    final docId = DayLog.dateKey(date);
    return _col.doc(docId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return DayLog(date: date.dateOnly);
      return DayLog.fromMap(data);
    });
  }

  Future<DayLog?> fetchDate(DateTime date) async {
    final docId = DayLog.dateKey(date);
    final snap = await _col.doc(docId).get();
    final data = snap.data();
    if (data == null) return null;
    return DayLog.fromMap(data);
  }

  Future<DayLog> fetchDateOrEmpty(DateTime date) async {
    final log = await fetchDate(date);
    return log ?? DayLog(date: date.dateOnly);
  }

  Future<void> save(DayLog log) async {
    final docId = log.docId;
    if (!log.hasAnyData) {
      // Hapus dokumen kosong agar tidak menumpuk.
      await _col.doc(docId).delete();
      return;
    }
    await _col.doc(docId).set(log.toMap());
  }

  Future<void> delete(DateTime date) async {
    await _col.doc(DayLog.dateKey(date)).delete();
  }

  /// Hapus semua log (untuk reset data).
  Future<void> clearAll() async {
    final snap = await _col.get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Filter dari list cached.
  static List<DayLog> rangeOf(List<DayLog> logs, DateTime from, DateTime to) {
    final start = from.dateOnly;
    final end = to.dateOnly;
    return logs.where((l) {
      final d = l.date.dateOnly;
      return (d.isAfter(start) || d.isSameDate(start)) &&
          (d.isBefore(end) || d.isSameDate(end));
    }).toList();
  }
}
