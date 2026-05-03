import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/models/enums.dart';
import '../data/partner_repository.dart';

final partnerRepositoryProvider = Provider<PartnerRepository>((ref) {
  return PartnerRepository();
});

/// Info tentang pasangan (male) yang sudah link ke kode female.
/// Null kalau belum ada yang link.
class LinkedPartnerInfo {
  const LinkedPartnerInfo({required this.uid, required this.name, this.email});

  final String uid;
  final String name;
  final String? email;
}

/// Stream info pasangan ter-link untuk female user. Emit `null` kalau:
/// - User bukan female, atau
/// - Female belum generate kode, atau
/// - Belum ada male yang pakai kode tersebut.
///
/// Sumber data: `partnerCodes/{myCode}` — male menulis `linkedUid/Name/Email`
/// di sana saat linking (lihat `PartnerRepository.linkMaleToCode`).
final linkedPartnerInfoProvider = StreamProvider<LinkedPartnerInfo?>((ref) {
  final ownProfile = ref.watch(ownProfileProvider).value;
  if (ownProfile == null) return Stream<LinkedPartnerInfo?>.value(null);
  if (ownProfile.gender != UserGender.female) {
    return Stream<LinkedPartnerInfo?>.value(null);
  }
  final code = ownProfile.partnerCode;
  if (code == null || code.isEmpty) {
    return Stream<LinkedPartnerInfo?>.value(null);
  }

  return FirebaseFirestore.instance
      .collection('partnerCodes')
      .doc(code)
      .snapshots()
      .map((snap) {
        final data = snap.data();
        if (data == null) return null;
        final linkedUid = data['linkedUid'] as String?;
        if (linkedUid == null || linkedUid.isEmpty) return null;
        return LinkedPartnerInfo(
          uid: linkedUid,
          name: (data['linkedName'] as String?)?.trim().isNotEmpty == true
              ? (data['linkedName'] as String).trim()
              : 'Pasangan',
          email: data['linkedEmail'] as String?,
        );
      });
});
