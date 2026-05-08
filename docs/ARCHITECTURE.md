# Arsitektur Project

## Overview

Project Vanila menggunakan **Feature-first architecture** dengan **Riverpod** sebagai state management dan **Firebase** sebagai backend.

## Struktur Folder

```
lib/
├── core/                  # Shared resources dan utilities
│   ├── constants/         # API keys, constants
│   ├── theme/            # AppColors, AppTheme, AppTypography
│   ├── utils/            # CycleCalculator, date helpers, device tier detection
│   └── widgets/          # GlassContainer, PrimaryButton, CycleRing, dsb.
├── data/                  # Data layer
│   ├── models/           # Cycle, DayLog, UserProfile, enums
│   └── repositories/     # CycleRepository, LogRepository, dsb.
├── features/             # Feature modules
│   ├── auth/            # Login, Sign Up, Google Sign-In
│   ├── calendar/        # Kalender siklus bulanan
│   ├── chat/            # AI Assistant untuk konsultasi kesehatan
│   ├── insights/        # Grafik & artikel kesehatan
│   ├── logging/         # Log harian (mood, gejala, flow)
│   ├── notifications/   # Notifikasi lokal
│   ├── onboarding/      # Onboarding multi-step
│   ├── partner/         # Fitur pasangan (kode link)
│   ├── profile/         # Profil & pengaturan
│   ├── splash/          # Splash screen dengan animasi
│   └── today/           # Dashboard utama
└── routing/             # GoRouter, MainShell
```

## Tech Stack

### Frontend
- **Framework**: Flutter 3.x
- **Language**: Dart 3.x
- **State Management**: flutter_riverpod ^2.6
- **Routing**: go_router ^14
- **UI**: Cupertino widgets (iOS-style)

### Backend
- **Auth**: Firebase Auth
- **Database**: Cloud Firestore
- **Hosting**: Firebase Hosting (optional)

### Third-party Services
- **AI Chat**: OpenRouter API
- **Notifications**: flutter_local_notifications
- **Charts**: fl_chart
- **Fonts**: google_fonts

## Data Flow

### Authentication Flow
```
User → LoginScreen → AuthRepository → Firebase Auth
                                    ↓
                              User Session (Riverpod)
                                    ↓
                            Protected Routes (GoRouter)
```

### Cycle Tracking Flow
```
User → CalendarScreen → CycleRepository → Firestore
                     ↓
              CycleCalculator (Local)
                     ↓
              Predictions & Forecasts
```

### Chat AI Flow
```
User → ChatScreen → ChatRepository → OpenRouter API
                     ↓
              Message History (Firestore)
```

## State Management

Riverpod providers digunakan untuk:
- **Global State**: User session, theme, notifications
- **Feature State**: Calendar data, logs, partner info
- **Async State**: Firestore queries, API calls

## Performance Optimization

### Device Tier Detection
- **High-end**: Full animations, blur effects
- **Mid-range**: Reduced blur, optimized animations
- **Low-end**: Minimal animations, solid backgrounds

### Tree-shaking
- Unused icons removed at build time
- Font optimization (97%+ reduction)

### Lazy Loading
- On-demand data fetching from Firestore
- Pagination for large datasets

## Security

- Firebase Rules untuk data access control
- API keys tidak di-commit ke repo
- Signing keys di-secure di local machine
