# Deployment Guide

## Prerequisites

- Flutter SDK 3.x+
- Android Studio / Xcode
- Firebase account
- OpenRouter API key (untuk fitur AI Chat)

## Build APK Release

### Build dengan API Key

```bash
# Build dengan --dart-define untuk API key
flutter build apk --release --split-per-abi --dart-define=OPENROUTER_API_KEY=your_key_here
```

### Output Files

APK akan di-generate di `build/app/outputs/flutter-apk/`:

| File | Target Device |
|------|---------------|
| `app-arm64-v8a-release.apk` | HP modern ARM 64-bit (paling umum) |
| `app-armeabi-v7a-release.apk` | HP lama ARM 32-bit |
| `app-x86_64-release.apk` | Emulator |

## Setup Signing Keys

### 1. Generate Keystore

```bash
keytool -genkey -v -keystore flo_track_release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias flo_track
```

### 2. Create key.properties

Buat file `android/key.properties`:

```properties
storePassword=your_password
keyPassword=your_password
keyAlias=flo_track
storeFile=flo_track_release.jks
```

### 3. Update build.gradle.kts

File ini sudah terkonfigurasi di project ini. Pastikan file `key.properties` ada dan tidak di-commit ke git.

## Firebase Deployment

### 1. Setup Firebase Project

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login ke Firebase
firebase login

# Configure project
flutterfire configure
```

### 2. Deploy ke Firebase Hosting (Optional)

```bash
# Build web version
flutter build web

# Deploy ke Firebase Hosting
firebase deploy
```

## Release Checklist

- [ ] Update version di `pubspec.yaml`
- [ ] Update CHANGELOG.md
- [ ] Test semua fitur utama
- [ ] Build APK release
- [ ] Test APK di device nyata
- [ ] Update Firebase rules jika perlu
- [ ] Deploy ke production
- [ ] Tag release di Git
- [ ] Update GitHub release notes

## Troubleshooting

### Build Error: Keystore not found

Pastikan file `android/key.properties` ada dan path ke keystore benar.

### Firebase Auth Error

Pastikan `google-services.json` sudah ada di `android/app/` dan `lib/firebase_options.dart` sudah dikonfigurasi.

### AI Chat tidak bekerja

Pastikan `OPENROUTER_API_KEY` sudah diset via `--dart-define` saat `flutter run` atau `flutter build`.
