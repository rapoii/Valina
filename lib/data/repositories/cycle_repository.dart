import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/date_x.dart';
import '../models/cycle.dart';

/// Repository data siklus menstruasi, disimpan di Firestore di
/// `users/{uid}/cycles/{cycleId}`.
class CycleRepository {
  CycleRepository({required this.uid, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const _uuid = Uuid();

  final String uid;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('users').doc(uid).collection('cycles');

  /// Stream semua siklus, di-sort dari yang terbaru ke yang terlama.
  Stream<List<Cycle>> watchAll() {
    return _col.orderBy('startDate', descending: true).snapshots().map((snap) {
      return snap.docs
          .map((d) => Cycle.fromMap(d.id, d.data()))
          .toList(growable: false);
    });
  }

  Future<List<Cycle>> fetchAll() async {
    final snap = await _col.orderBy('startDate', descending: true).get();
    return snap.docs.map((d) => Cycle.fromMap(d.id, d.data())).toList();
  }

  /// Siklus terbaru dari list cached (sudah tersortir di stream).
  static Cycle? latestOf(List<Cycle> cycles) =>
      cycles.isEmpty ? null : cycles.first;

  /// Siklus aktif (belum punya endDate atau sedang berlangsung).
  static Cycle? ongoingOf(List<Cycle> cycles) =>
      cycles.where((c) => c.endDate == null).firstOrNull;

  /// Mencari siklus yang melingkupi tanggal tertentu di list cached.
  static Cycle? findByDateIn(List<Cycle> cycles, DateTime date) {
    final d = date.dateOnly;
    for (final c in cycles) {
      final start = c.startDate.dateOnly;
      final end = (c.endDate ?? c.startDate).dateOnly;
      if ((d.isAfter(start) || d.isSameDate(start)) &&
          (d.isBefore(end) || d.isSameDate(end))) {
        return c;
      }
    }
    return null;
  }

  Future<Cycle> create({required DateTime startDate, DateTime? endDate}) async {
    final cycle = Cycle(
      id: _uuid.v4(),
      startDate: startDate.dateOnly,
      endDate: endDate?.dateOnly,
    );
    await _col.doc(cycle.id).set(cycle.toMap());
    return cycle;
  }

  Future<void> update(Cycle cycle) async {
    await _col.doc(cycle.id).set(cycle.toMap(), SetOptions(merge: true));
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  /// Hapus semua dokumen di koleksi (untuk reset data).
  Future<void> clearAll() async {
    final snap = await _col.get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
