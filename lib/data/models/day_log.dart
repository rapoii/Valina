import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

/// Log harian — semua catatan gejala/mood/aktivitas untuk satu tanggal.
///
/// Disimpan di Firestore di `users/{uid}/logs/{yyyy-MM-dd}`.
class DayLog {
  DayLog({
    required this.date,
    this.flowIntensity,
    List<Mood>? moods,
    List<Symptom>? symptoms,
    this.discharge,
    this.sexualActivity,
    this.bbt,
    this.weight,
    this.sleepHours,
    this.waterIntakeGlasses,
    this.notes,
  }) : moods = moods ?? <Mood>[],
       symptoms = symptoms ?? <Symptom>[];

  DateTime date;
  FlowIntensity? flowIntensity;
  List<Mood> moods;
  List<Symptom> symptoms;
  Discharge? discharge;
  SexualActivity? sexualActivity;

  /// Basal Body Temperature (Celsius).
  double? bbt;
  double? weight;
  double? sleepHours;
  int? waterIntakeGlasses;
  String? notes;

  bool get hasAnyData =>
      flowIntensity != null ||
      moods.isNotEmpty ||
      symptoms.isNotEmpty ||
      discharge != null ||
      sexualActivity != null ||
      bbt != null ||
      weight != null ||
      sleepHours != null ||
      waterIntakeGlasses != null ||
      (notes != null && notes!.trim().isNotEmpty);

  /// Key untuk Firestore doc id (format yyyy-MM-dd).
  static String dateKey(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  String get docId => dateKey(date);

  Map<String, dynamic> toMap() => {
    'date': Timestamp.fromDate(date),
    'flowIntensity': flowIntensity?.name,
    'moods': moods.map((m) => m.name).toList(),
    'symptoms': symptoms.map((s) => s.name).toList(),
    'discharge': discharge?.name,
    'sexualActivity': sexualActivity?.name,
    'bbt': bbt,
    'weight': weight,
    'sleepHours': sleepHours,
    'waterIntakeGlasses': waterIntakeGlasses,
    'notes': notes,
  };

  static DayLog fromMap(Map<String, dynamic> map) {
    return DayLog(
      date: _toDate(map['date']) ?? DateTime.now(),
      flowIntensity: enumFromName(
        FlowIntensity.values,
        map['flowIntensity'] as String?,
      ),
      moods: _enumList(Mood.values, map['moods']),
      symptoms: _enumList(Symptom.values, map['symptoms']),
      discharge: enumFromName(Discharge.values, map['discharge'] as String?),
      sexualActivity: enumFromName(
        SexualActivity.values,
        map['sexualActivity'] as String?,
      ),
      bbt: (map['bbt'] as num?)?.toDouble(),
      weight: (map['weight'] as num?)?.toDouble(),
      sleepHours: (map['sleepHours'] as num?)?.toDouble(),
      waterIntakeGlasses: (map['waterIntakeGlasses'] as num?)?.toInt(),
      notes: map['notes'] as String?,
    );
  }

  static DateTime? _toDate(Object? v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  static List<T> _enumList<T extends Enum>(List<T> values, Object? raw) {
    if (raw is! List) return <T>[];
    final result = <T>[];
    for (final item in raw) {
      final parsed = enumFromName(values, item as String?);
      if (parsed != null) result.add(parsed);
    }
    return result;
  }
}
