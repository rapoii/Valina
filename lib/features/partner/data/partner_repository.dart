import 'package:cloud_firestore/cloud_firestore.dart';

import 'code_generator.dart';

/// Exception yang ditampilkan ke user dengan pesan bahasa Indonesia.
class PartnerException implements Exception {
  const PartnerException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Repository untuk fitur pasangan. Handle:
///
/// - Generate & simpan kode untuk female di `partnerCodes/{code}`.
/// - Lookup kode untuk male & simpan `partnerUid` di profile male.
/// - Revoke link dari kedua sisi.
///
/// Semua method throw `PartnerException` dengan pesan user-friendly kalau gagal.
class PartnerRepository {
  PartnerRepository({
    FirebaseFirestore? firestore,
    PartnerCodeGenerator? codeGenerator,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _codeGen = codeGenerator ?? PartnerCodeGenerator();

  final FirebaseFirestore _firestore;
  final PartnerCodeGenerator _codeGen;

  CollectionReference<Map<String, dynamic>> get _codesCol =>
      _firestore.collection('partnerCodes');

  DocumentReference<Map<String, dynamic>> _profileDoc(String uid) =>
      _firestore.collection('users').doc(uid).collection('profile').doc('data');

  /// Generate kode baru untuk female, simpan mapping ke Firestore, dan
  /// update `partnerCode` di profile. Kalau sudah punya kode lama, hapus dulu
  /// (regenerate effect).
  ///
  /// Return kode yang di-generate.
  Future<String> generateCodeForFemale({
    required String femaleUid,
    String? previousCode,
  }) async {
    // Hapus mapping lama kalau ada — ini yang bikin link lama otomatis putus.
    if (previousCode != null && previousCode.isNotEmpty) {
      try {
        await _codesCol.doc(previousCode).delete();
      } catch (_) {
        // Ignore — mungkin sudah dihapus atau tidak ada.
      }
    }

    // Retry sampai dapat kode yang belum dipakai (probabilitas collision
    // ~1/trilion per percobaan, tapi tetep safe guard).
    String? chosen;
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _codeGen.generate();
      final doc = _codesCol.doc(code);
      final snap = await doc.get();
      if (!snap.exists) {
        await doc.set({
          'ownerUid': femaleUid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        chosen = code;
        break;
      }
    }
    if (chosen == null) {
      throw const PartnerException(
        'Gagal membuat kode unik. Coba lagi sebentar.',
      );
    }

    await _profileDoc(
      femaleUid,
    ).set({'partnerCode': chosen}, SetOptions(merge: true));

    return chosen;
  }

  /// Lookup kode & link male ke female. Throws `PartnerException` kalau
  /// kode tidak valid / tidak ditemukan / mencoba link ke diri sendiri.
  ///
  /// [maleName] & [maleEmail] di-tuliskan ke `partnerCodes/{code}` supaya
  /// female bisa melihat "Pasangan terhubung: [nama]" tanpa harus membaca
  /// profile male (yang belum tentu bisa dibaca cross-user).
  ///
  /// Return UID female yang baru di-link.
  Future<String> linkMaleToCode({
    required String maleUid,
    required String rawCode,
    String? maleName,
    String? maleEmail,
  }) async {
    if (!PartnerCodeGenerator.isValid(rawCode)) {
      throw const PartnerException(
        'Format kode tidak valid. Kode harus 8 karakter huruf/angka.',
      );
    }
    final code = PartnerCodeGenerator.normalize(rawCode);

    final snap = await _codesCol.doc(code).get();
    final data = snap.data();
    if (!snap.exists || data == null) {
      throw const PartnerException(
        'Kode tidak ditemukan. Pastikan kode benar & pasanganmu sudah generate kode.',
      );
    }
    final ownerUid = data['ownerUid'] as String?;
    if (ownerUid == null || ownerUid.isEmpty) {
      throw const PartnerException(
        'Kode rusak. Minta pasangan generate ulang.',
      );
    }
    if (ownerUid == maleUid) {
      throw const PartnerException('Kamu tidak bisa link ke diri sendiri.');
    }

    await _profileDoc(
      maleUid,
    ).set({'partnerUid': ownerUid}, SetOptions(merge: true));

    // Tulis info linked partner ke dokumen kode — supaya sisi female bisa
    // lihat siapa yang memakai kode-nya tanpa perlu baca profile male.
    // Best-effort: kalau gagal, female akan tetap lihat view "menunggu".
    try {
      await _codesCol.doc(code).update({
        'linkedUid': maleUid,
        'linkedName': maleName,
        'linkedEmail': maleEmail,
        'linkedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Ignore — linking tetap sukses dari sisi male.
    }

    return ownerUid;
  }

  /// Revoke dari sisi female: hapus mapping kode + clear `partnerCode`.
  /// Male yang ter-link akan otomatis kehilangan akses (Firestore rules
  /// menolak karena male.partnerUid tidak match lagi — tapi tetap match di
  /// profile, jadi kita perlu extra step untuk hard-disconnect).
  ///
  /// Karena male's profile milik male, female TIDAK bisa langsung clear
  /// `partnerUid` di profile male. Male akan melihat error saat next read
  /// dan dipaksa unlink sendiri. Ini trade-off yang acceptable.
  Future<void> revokeFromFemale({
    required String femaleUid,
    String? code,
  }) async {
    if (code != null && code.isNotEmpty) {
      try {
        await _codesCol.doc(code).delete();
      } catch (_) {}
    }
    await _profileDoc(
      femaleUid,
    ).set({'partnerCode': null}, SetOptions(merge: true));
  }

  /// Revoke dari sisi male: clear `partnerUid` di profile sendiri, dan
  /// best-effort clear `linkedUid/Name/Email` di `partnerCodes/{code}` supaya
  /// sisi female balik lagi ke view "menunggu".
  Future<void> revokeFromMale({required String maleUid}) async {
    // Baca partnerUid dulu supaya tahu female mana yang ter-link.
    String? partnerUid;
    try {
      final maleSnap = await _profileDoc(maleUid).get();
      partnerUid = maleSnap.data()?['partnerUid'] as String?;
    } catch (_) {
      // Ignore — tetap lanjut clear profile di bawah.
    }

    await _profileDoc(
      maleUid,
    ).set({'partnerUid': null}, SetOptions(merge: true));

    // Best-effort: cari kode female & hapus linkedUid kalau itu kita sendiri.
    if (partnerUid != null && partnerUid.isNotEmpty) {
      try {
        final codes = await _codesCol
            .where('ownerUid', isEqualTo: partnerUid)
            .get();
        for (final d in codes.docs) {
          final linked = d.data()['linkedUid'] as String?;
          if (linked == maleUid) {
            await d.reference.update({
              'linkedUid': FieldValue.delete(),
              'linkedName': FieldValue.delete(),
              'linkedEmail': FieldValue.delete(),
              'linkedAt': FieldValue.delete(),
            });
          }
        }
      } catch (_) {
        // Tidak kritikal — female bisa regenerate kode kalau view tersangkut.
      }
    }
  }
}
