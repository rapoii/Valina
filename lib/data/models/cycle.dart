import 'package:cloud_firestore/cloud_firestore.dart';

/// Catatan satu siklus menstruasi (mulai sampai selesai).
///
/// Disimpan di Firestore di `users/{uid}/cycles/{cycleId}`.
class Cycle {
  Cycle({
    required this.id,
    required this.startDate,
    this.endDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String id;
  DateTime startDate;
  DateTime? endDate;
  DateTime createdAt;

  /// Panjang haid (hari) bila sudah selesai, jika tidak 0.
  int get periodLength {
    if (endDate == null) return 0;
    return endDate!.difference(startDate).inDays + 1;
  }

  bool get isOngoing => endDate == null;

  Map<String, dynamic> toMap() => {
    'startDate': Timestamp.fromDate(startDate),
    'endDate': endDate == null ? null : Timestamp.fromDate(endDate!),
    'createdAt': Timestamp.fromDate(createdAt),
  };

  static Cycle fromMap(String id, Map<String, dynamic> map) {
    return Cycle(
      id: id,
      startDate: _toDate(map['startDate']) ?? DateTime.now(),
      endDate: _toDate(map['endDate']),
      createdAt: _toDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _toDate(Object? v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  Cycle copyWith({DateTime? startDate, DateTime? endDate}) {
    return Cycle(
      id: id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt,
    );
  }
}
