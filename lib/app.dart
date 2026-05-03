import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show DefaultMaterialLocalizations, PerformanceOverlay;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/theme/app_theme.dart';
import 'data/models/enums.dart';
import 'data/models/user_profile.dart';
import 'routing/app_router.dart';

class ValinaApp extends ConsumerWidget {
  const ValinaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Auto-heal stale male link.
    //
    // Skenario: female revoke pasangan → dia delete partnerCodes/{code} +
    // set profile.partnerCode = null. Tapi female TIDAK bisa write ke profile
    // male, jadi male.partnerUid masih nempel ke female.uid → male masih
    // ngeliat data female (karena rules `isLinkedPartnerOf` cuma cek dari sisi
    // male). Auto-heal ini ngebersihin male.partnerUid begitu dia detect
    // female sudah revoke (partnerCode null) atau profile-nya sudah hilang.
    ref.listen<AsyncValue<UserProfile?>>(profileProvider, (_, next) {
      next.whenData((partnerProfile) {
        final ownProfile = ref.read(ownProfileProvider).value;
        if (ownProfile == null) return;
        if (ownProfile.gender != UserGender.male) return;
        final partnerUid = ownProfile.partnerUid;
        if (partnerUid == null || partnerUid.isEmpty) return;

        // Stale kalau profile partner ga ada / partnerCode-nya null/empty.
        final stale =
            partnerProfile == null ||
            partnerProfile.partnerCode == null ||
            partnerProfile.partnerCode!.isEmpty;
        if (!stale) return;

        // Fire-and-forget: clear partnerUid. Router redirect akan ngarahin
        // ke /onboarding (relink mode).
        ownProfile.partnerUid = null;
        ref.read(profileRepositoryProvider).save(ownProfile);
      });
    });

    return CupertinoApp.router(
      title: 'Valina',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      localizationsDelegates: const [
        DefaultCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
      ],
      // Performance overlay untuk debug mode — tampilkan FPS meter (UI +
      // raster threads). Wajib pakai `Positioned` dengan bounds horizontal
      // yang lengkap (left + right) supaya `PerformanceOverlay` punya width
      // terbatas — kalau tidak akan throw "infinite size" dan layar jadi
      // hitam total.
      builder: kDebugMode
          ? (context, child) => Stack(
              children: [
                child!,
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 80,
                  child: IgnorePointer(child: PerformanceOverlay.allEnabled()),
                ),
              ],
            )
          : null,
    );
  }
}
