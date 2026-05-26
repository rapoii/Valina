# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common commands

- Install dependencies: `flutter pub get`
- Run the app: `flutter run`
- Run with AI chat key: `flutter run --dart-define=OPENROUTER_API_KEY=your_key_here`
- Analyze/lint: `flutter analyze`
- Format changed Dart files: `dart format <files>`
- Run all tests: `flutter test`
- Run one test file: `flutter test test/cycle_calculator_test.dart`
- Run a single named test: `flutter test test/cycle_calculator_test.dart --name "fertile window"`
- Build split release APKs: `flutter build apk --release --split-per-abi`
- Build release APKs with AI key: `flutter build apk --release --split-per-abi --dart-define=OPENROUTER_API_KEY=your_key_here`

## Setup notes

- Firebase config is required but not committed. Generate `lib/firebase_options.dart` with `flutterfire configure`, or copy from `lib/firebase_options.dart.example` if present and fill values manually.
- Android Firebase config (`google-services.json`), signing files (`android/key.properties`, `.jks`), launch configs, and API keys are intentionally excluded from git.
- The AI chat feature reads `OPENROUTER_API_KEY` from `--dart-define`; do not add a hardcoded key.

## Architecture overview

This is a Flutter/Dart app (`flo_track`, UI branded as Valina/Vanila) for menstrual cycle tracking, reproductive health logs, partner sharing, notifications, and AI chat. It uses a feature-first structure with shared core utilities and Firestore-backed repositories.

### App startup and routing

- [lib/main.dart](lib/main.dart) initializes Flutter bindings, high refresh rate on Android, Firebase, Firestore offline persistence, Indonesian date formatting, local notification service, then runs `ProviderScope(child: ValinaApp())`.
- [lib/app.dart](lib/app.dart) builds a `CupertinoApp.router`, uses Indonesian locale, applies Cupertino theme, and includes an auto-heal listener for stale male partner links after female revoke.
- [lib/routing/app_router.dart](lib/routing/app_router.dart) defines GoRouter routes and redirect rules. Redirects depend on auth state and the own user profile, not the effective partner profile. Male users without `partnerUid` are sent back to onboarding for relinking; male users are blocked from cycle settings.
- [lib/routing/main_shell.dart](lib/routing/main_shell.dart) hosts the tabbed shell for Today, Calendar, Insights, Chat, and Profile.

### State and data model

- Riverpod is the central state mechanism. Cross-feature providers live in [lib/core/providers.dart](lib/core/providers.dart).
- `ownProfileProvider` always represents the logged-in user's own profile.
- `effectiveUidProvider` returns the partner UID for linked male users, otherwise the own UID. Read providers for cycles/logs/forecast use this effective UID so male users see partner data in read-only mode.
- Repository providers are for writes and are intentionally own-user scoped. Do not use `effectiveUidProvider` for writes.
- Privacy gates are derived in [lib/core/providers.dart](lib/core/providers.dart): `isReadOnlyProvider`, `canViewPhaseProvider`, `canViewLogsProvider`, and `canViewNotesProvider`. Any new partner-visible UI must use these gates before showing phase predictions, logs, or notes.

### Persistence layout

Firestore repositories store data under per-user collections:

- Profile: `users/{uid}/profile/data` via [lib/data/repositories/profile_repository.dart](lib/data/repositories/profile_repository.dart)
- Cycles: `users/{uid}/cycles/{cycleId}` via [lib/data/repositories/cycle_repository.dart](lib/data/repositories/cycle_repository.dart)
- Daily logs: `users/{uid}/logs/{yyyy-MM-dd}` via [lib/data/repositories/log_repository.dart](lib/data/repositories/log_repository.dart)
- Article bookmarks are own-user preferences via `ArticleRepository`.
- Partner linking uses top-level `partnerCodes/{code}` mappings plus `partnerUid`/`partnerCode` fields on profile documents through [lib/features/partner/data/partner_repository.dart](lib/features/partner/data/partner_repository.dart).

### Feature organization

- [lib/features/auth/](lib/features/auth/) handles Firebase Auth, login, signup, and Google Sign-In.
- [lib/features/onboarding/](lib/features/onboarding/) collects profile setup data, including gender and partner-code flow.
- [lib/features/today/](lib/features/today/) is the dashboard using forecast, daily log, partner privacy, and quick log UI.
- [lib/features/calendar/](lib/features/calendar/) renders month forecasts, actual period/log markers, and date details.
- [lib/features/logging/](lib/features/logging/) owns the log sheet and input widgets for mood, symptoms, flow, discharge, and sexual activity.
- [lib/features/insights/](lib/features/insights/) shows cycle analytics and article content.
- [lib/features/profile/](lib/features/profile/) owns profile/settings screens, partner settings, cycle settings, and notification settings.
- [lib/features/notifications/notification_service.dart](lib/features/notifications/notification_service.dart) wraps `flutter_local_notifications`; permission requests are separate from initialization.
- [lib/features/chat/](lib/features/chat/) stores chat sessions/messages and calls OpenRouter through [lib/features/chat/data/openrouter_service.dart](lib/features/chat/data/openrouter_service.dart).

### Cycle forecast logic

- Core cycle calculations are in [lib/core/utils/cycle_calculator.dart](lib/core/utils/cycle_calculator.dart).
- `todayForecastProvider` and `forecastForDateProvider` derive `CycleForecast` from effective cycles, effective profile fallback lengths, and effective logs.
- Existing unit coverage is concentrated in [test/cycle_calculator_test.dart](test/cycle_calculator_test.dart); add focused tests there for forecast/date math changes.

### UI conventions

- The app is Cupertino/iOS-style. Prefer Cupertino widgets and existing theme tokens in [lib/core/theme/](lib/core/theme/).
- Shared visual primitives live in [lib/core/widgets/](lib/core/widgets/). Feature-specific widgets stay inside their feature directory.
- User-facing copy is primarily Indonesian.
