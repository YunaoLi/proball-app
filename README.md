# Wicked Rolling Ball Pro

AI-powered IoT pet toy companion app. Cross-platform (iOS + Android).

## Overview

- **UI-first, mock data** — Runs fully without hardware
- **Production-quality** — Suitable for investor demos
- **BLE-ready** — Single swap point to integrate real hardware later

## Getting Started

```bash
flutter pub get
flutter run
```

## Architecture

```
lib/
├── app/          — Theme, routes, shell
├── core/         — Constants, utils, shared widgets
├── features/     — Dashboard, Activity, Map, Reports, Settings
├── models/       — Domain models (BallStatus, PlayStats, AiReport, etc.)
├── services/     — DeviceService interface, MockDeviceService, BleDeviceService (TODO)
└── main.dart
```

## Features

- **Dashboard** — Device status, play stats, pet mood, Start/Stop Play
- **Activity** — Recent sessions, calories/duration charts, mock historical data
- **Map** — Abstract indoor map, ball path, high-activity zones, AI insights
- **Reports** — AI analysis (session summary, calories, mood, confidence) after ~3 min idle
- **Settings** — Connection toggle, about

## BLE Integration

To switch to real hardware, change one line in `lib/app/app.dart`:

```dart
create: (_) => BleDeviceService(),  // instead of MockDeviceService()
```

No other UI code changes required.

# Wicked Rolling Ball Pro App

Flutter-based mobile application for the Wicked Rolling Ball Pro.

## Features
- Real-time play session tracking
- Battery-aware safety handling
- AI-generated play reports
- Map-based activity visualization
- BLE-ready architecture (mock data for now)

## Tech Stack
- Flutter (Dart)
- MVVM-style architecture
- Mock data → BLE-ready
- Designed for ESP32 IoT integration

## Status
🚧 UI + architecture complete  
🔌 BLE integration coming soon


## Tech Stack

- Flutter 3.x
- Provider (state management)
- fl_chart (bar charts)
