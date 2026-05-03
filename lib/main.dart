import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'features/notifications/notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Aktifkan refresh rate tertinggi yang didukung device (90/120/144Hz).
  // Hanya berlaku untuk Android — iOS handled by Info.plist
  // (CADisableMinimumFrameDurationOnPhone = true).
  // Best-effort: kalau gagal (web/desktop/tidak didukung), abaikan.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (_) {
      // Ignore — ada device lama yang tidak punya display mode API.
    }
  }

  // Inisialisasi Firebase.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Aktifkan offline persistence Firestore (works untuk web + mobile + desktop).
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Inisialisasi locale Indonesia untuk DateFormat.
  await initializeDateFormatting('id_ID');

  // Notifikasi (lazy init — tidak request permission di sini).
  await NotificationService.instance.init();

  runApp(const ProviderScope(child: ValinaApp()));
}
