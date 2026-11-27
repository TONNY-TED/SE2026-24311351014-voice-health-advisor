# Operations Runbook — VoiceHealth

## Purpose

This runbook describes operational procedures for VoiceHealth.

## Prerequisites

- Flutter SDK.
- Android device or emulator.
- Firebase or backend dependencies as configured.

## Build and run

```bash
flutter build apk --debug
flutter run -d <device>
```

## Deployment

- Build release APK.
- Distribute to testers.
- Monitor permissions and services.

## Monitoring and rollback

- Watch logs for speech, TTS, and NLP failures.
- Roll back to last known good release if critical failures occur.
