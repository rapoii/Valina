import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

/// Profil user, disimpan di Firestore di `users/{uid}/profile/data`.
class UserProfile {
  UserProfile({
    required this.name,
    this.email,
    this.gender = UserGender.female,
    this.dateOfBirth,
    this.lastPeriodDate,
    this.avgCycleLength = 28,
    this.avgPeriodLength = 5,
    this.goal = CycleGoal.trackCycle,
    this.dailyReminderEnabled = false,
    this.dailyReminderHour = 20,
    this.dailyReminderMinute = 0,
    this.periodReminderEnabled = true,
    this.ovulationReminderEnabled = true,
    this.partnerCode,
    this.partnerUid,
    this.sharePhase = true,
    this.shareLogs = true,
    this.shareNotes = false,
    this.createdAt,
  });

  String name;
  String? email;
  UserGender gender;
  DateTime? dateOfBirth;
  DateTime? lastPeriodDate;
  int avgCycleLength;
  int avgPeriodLength;
  CycleGoal goal;
  bool dailyReminderEnabled;
  int dailyReminderHour;
  int dailyReminderMinute;
  bool periodReminderEnabled;
  bool ovulationReminderEnabled;

  /// Untuk female: kode yang dibagikan ke pasangan (null kalau belum generate).
  String? partnerCode;

  /// Untuk male: UID female yang sudah di-link (null kalau belum linked).
  String? partnerUid;

  /// Privasi: apakah pasangan boleh lihat prediksi fase siklus.
  /// Default true (ini inti fiturnya — kalau false cowok tidak lihat apa-apa).
  bool sharePhase;

  /// Privasi: apakah pasangan boleh lihat log harian (flow, mood, gejala).
  bool shareLogs;

  /// Privasi: apakah pasangan boleh lihat catatan pribadi (notes).
  bool shareNotes;

  DateTime? createdAt;

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'gender': gender.name,
    'dateOfBirth': dateOfBirth == null
        ? null
        : Timestamp.fromDate(dateOfBirth!),
    'lastPeriodDate': lastPeriodDate == null
        ? null
        : Timestamp.fromDate(lastPeriodDate!),
    'avgCycleLength': avgCycleLength,
    'avgPeriodLength': avgPeriodLength,
    'goal': goal.name,
    'dailyReminderEnabled': dailyReminderEnabled,
    'dailyReminderHour': dailyReminderHour,
    'dailyReminderMinute': dailyReminderMinute,
    'periodReminderEnabled': periodReminderEnabled,
    'ovulationReminderEnabled': ovulationReminderEnabled,
    'partnerCode': partnerCode,
    'partnerUid': partnerUid,
    'sharePhase': sharePhase,
    'shareLogs': shareLogs,
    'shareNotes': shareNotes,
    'createdAt': createdAt == null
        ? FieldValue.serverTimestamp()
        : Timestamp.fromDate(createdAt!),
  };

  static UserProfile fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: (map['name'] as String?) ?? 'Sahabat',
      email: map['email'] as String?,
      // Default female untuk user lama yang belum punya field gender.
      gender:
          enumFromName(UserGender.values, map['gender'] as String?) ??
          UserGender.female,
      dateOfBirth: _toDate(map['dateOfBirth']),
      lastPeriodDate: _toDate(map['lastPeriodDate']),
      avgCycleLength: (map['avgCycleLength'] as num?)?.toInt() ?? 28,
      avgPeriodLength: (map['avgPeriodLength'] as num?)?.toInt() ?? 5,
      goal:
          enumFromName(CycleGoal.values, map['goal'] as String?) ??
          CycleGoal.trackCycle,
      dailyReminderEnabled: (map['dailyReminderEnabled'] as bool?) ?? false,
      dailyReminderHour: (map['dailyReminderHour'] as num?)?.toInt() ?? 20,
      dailyReminderMinute: (map['dailyReminderMinute'] as num?)?.toInt() ?? 0,
      periodReminderEnabled: (map['periodReminderEnabled'] as bool?) ?? true,
      ovulationReminderEnabled:
          (map['ovulationReminderEnabled'] as bool?) ?? true,
      partnerCode: map['partnerCode'] as String?,
      partnerUid: map['partnerUid'] as String?,
      sharePhase: (map['sharePhase'] as bool?) ?? true,
      shareLogs: (map['shareLogs'] as bool?) ?? true,
      shareNotes: (map['shareNotes'] as bool?) ?? false,
      createdAt: _toDate(map['createdAt']),
    );
  }

  static DateTime? _toDate(Object? v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  UserProfile copyWith({
    String? name,
    String? email,
    UserGender? gender,
    DateTime? dateOfBirth,
    DateTime? lastPeriodDate,
    int? avgCycleLength,
    int? avgPeriodLength,
    CycleGoal? goal,
    bool? dailyReminderEnabled,
    int? dailyReminderHour,
    int? dailyReminderMinute,
    bool? periodReminderEnabled,
    bool? ovulationReminderEnabled,
    String? partnerCode,
    String? partnerUid,
    bool? sharePhase,
    bool? shareLogs,
    bool? shareNotes,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      lastPeriodDate: lastPeriodDate ?? this.lastPeriodDate,
      avgCycleLength: avgCycleLength ?? this.avgCycleLength,
      avgPeriodLength: avgPeriodLength ?? this.avgPeriodLength,
      goal: goal ?? this.goal,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderHour: dailyReminderHour ?? this.dailyReminderHour,
      dailyReminderMinute: dailyReminderMinute ?? this.dailyReminderMinute,
      periodReminderEnabled:
          periodReminderEnabled ?? this.periodReminderEnabled,
      ovulationReminderEnabled:
          ovulationReminderEnabled ?? this.ovulationReminderEnabled,
      partnerCode: partnerCode ?? this.partnerCode,
      partnerUid: partnerUid ?? this.partnerUid,
      sharePhase: sharePhase ?? this.sharePhase,
      shareLogs: shareLogs ?? this.shareLogs,
      shareNotes: shareNotes ?? this.shareNotes,
      createdAt: createdAt,
    );
  }
}
