<div align="center">

# 🌸 Vanila

**Aplikasi pelacak siklus menstruasi & kesehatan reproduksi wanita**  
*Desain terinspirasi Apple Human Interface Guidelines*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%2B%20Auth-FFCA28?style=flat-square&logo=firebase&logoColor=black)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

</div>

---

## ✨ Fitur Utama

| Fitur | Deskripsi |
|-------|-----------|
| 📅 **Kalender Siklus** | Visualisasi siklus haid bulanan dengan prediksi otomatis |
| 📊 **Insights & Grafik** | Analisis panjang siklus, pola, dan tren kesehatan |
| 📝 **Daily Log** | Catat mood, gejala, dan intensitas aliran setiap hari |
| 🔔 **Notifikasi Cerdas** | Pengingat haid, ovulasi, dan jadwal lainnya |
| 👫 **Fitur Pasangan** | Hubungkan akun dengan pasangan via kode unik |
| 🔐 **Autentikasi Aman** | Login via Email/Password atau Google Sign-In |
| 🤖 **AI Assistant** | Chat dengan AI untuk konsultasi kesehatan reproduksi |
| 🌙 **Desain iOS-style** | UI frosted glass, Cupertino widgets, dark/light mode |
| ⚡ **Performance Optimized** | Device tier detection, 60fps+ smooth animations |

---

## 📱 Screenshots

> *Coming soon — screenshots akan ditambahkan setelah UI final*

---

## 🏗️ Arsitektur

Project ini menggunakan **Feature-first architecture** dengan **Riverpod** sebagai state management.

```
lib/
├── core/
│   ├── theme/          # AppColors, AppTheme, AppTypography
│   ├── utils/          # CycleCalculator, date helpers, device tier detection
│   └── widgets/        # GlassContainer, PrimaryButton, CycleRing, dsb.
├── data/
│   ├── models/         # Cycle, DayLog, UserProfile, enums
│   └── repositories/   # CycleRepository, LogRepository, dsb.
├── features/
│   ├── auth/           # Login, Sign Up, Google Sign-In
│   ├── calendar/       # Kalender siklus bulanan
│   ├── chat/           # AI Assistant untuk konsultasi kesehatan
│   ├── insights/       # Grafik & artikel kesehatan
│   ├── logging/        # Log harian (mood, gejala, flow)
│   ├── notifications/  # Notifikasi lokal
│   ├── onboarding/     # Onboarding multi-step
│   ├── partner/        # Fitur pasangan (kode link)
│   ├── profile/        # Profil & pengaturan
│   ├── splash/         # Splash screen dengan animasi
│   └── today/          # Dashboard utama
└── routing/            # GoRouter, MainShell
```

---

## 🛠️ Tech Stack

- **Framework** — [Flutter](https://flutter.dev) 3.x
- **State Management** — [flutter_riverpod](https://riverpod.dev) ^2.6
- **Routing** — [go_router](https://pub.dev/packages/go_router) ^14
- **Backend** — [Firebase Auth](https://firebase.google.com/products/auth) + [Cloud Firestore](https://firebase.google.com/products/firestore)
- **Auth Provider** — [Google Sign-In](https://pub.dev/packages/google_sign_in)
- **Notifikasi** — [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- **Charts** — [fl_chart](https://pub.dev/packages/fl_chart)
- **Fonts** — [google_fonts](https://pub.dev/packages/google_fonts)

---

## 🚀 Cara Setup & Jalankan

### 1. Clone repo

```bash
git clone https://github.com/rapoii/vanila.git
cd vanila
```

### 2. Setup Firebase

File `google-services.json` dan `lib/firebase_options.dart` tidak di-include di repo karena bersifat sensitif.

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login ke Firebase
firebase login

# Generate konfigurasi Firebase untuk project kamu
flutterfire configure
```

Atau copy file contoh dan isi manual:

```bash
cp lib/firebase_options.dart.example lib/firebase_options.dart
# Edit firebase_options.dart dengan config Firebase kamu
```

### 2.1 Setup OpenRouter API Key (untuk Chat AI)

Fitur AI Assistant membaca API key dari `--dart-define`:

```bash
flutter run --dart-define=OPENROUTER_API_KEY=your_key_here
flutter build apk --release --split-per-abi --dart-define=OPENROUTER_API_KEY=your_key_here
```

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Jalankan

```bash
flutter run
```

---

## 📦 Build APK Release

```bash
# APK terpisah per arsitektur (lebih kecil)
flutter build apk --release --split-per-abi

# Output:
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk   ← HP modern
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk ← HP lama
# build/app/outputs/flutter-apk/app-x86_64-release.apk      ← Emulator
```

---

## 🔒 Keamanan & Privasi

- File `google-services.json`, `lib/firebase_options.dart`, `android/key.properties`, dan `.jks` **tidak di-commit** ke repo.
- Data siklus disimpan secara private di Firestore dengan rules per-user.
- Autentikasi menggunakan Firebase Auth yang telah diverifikasi Google.

---

## 🤝 Kontribusi

Pull request sangat diterima! Untuk perubahan besar, buka issue terlebih dahulu.

1. Fork repo
2. Buat branch fitur: `git checkout -b feat/nama-fitur`
3. Commit: `git commit -m 'feat: tambah fitur X'`
4. Push: `git push origin feat/nama-fitur`
5. Buka Pull Request

---

## 📄 Lisensi

Distributed under the MIT License. See `LICENSE` for more information.

---

<div align="center">
  Made with ❤️ by <a href="https://github.com/rapoii">rapoii</a>
</div>
