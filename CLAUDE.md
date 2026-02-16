# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Pepa Ticket** (`evento_ticket_scanner`) — a Flutter QR code scanner app for event ticket verification. Scans tickets, verifies them against a backend API at `https://ticket.pepa.mn`, and manages scan history locally.

## Common Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected device
flutter run -d chrome    # Run on web
flutter run -d ios       # Run on iOS simulator
flutter run -d android   # Run on Android emulator
flutter analyze          # Run linter (uses flutter_lints)
flutter test             # Run tests
flutter test test/widget_test.dart  # Run single test
```

## Architecture

**State Management:** Provider (ChangeNotifier pattern) with MultiProvider at app root in `main.dart`.

**Module structure under `lib/`:**

| Module      | Purpose                                                 |
| ----------- | ------------------------------------------------------- |
| `auth/`     | Login flow, token persistence, user profile             |
| `home/`     | Dashboard with event/ticket data, filtering, pagination |
| `scanner/`  | QR camera view, scan verification, duplicate prevention |
| `history/`  | Local scan history (SharedPreferences)                  |
| `profile/`  | User profile display, logout                            |
| `settings/` | Theme mode, vibration toggle                            |
| `services/` | API client, branding/logo caching, device ID            |
| `common/`   | Shared colors, widgets, utilities                       |

**5 Providers:**

- `AuthProvider` — auth state, token, user profile (persisted via SharedPreferences)
- `DashboardProvider` — events, tickets, filtering, pagination (loads 10 at a time)
- `ScannerProvider` — scan locking, camera control, 3-second debounce
- `ScanHistoryProvider` — local scan history (SharedPreferences, version 2)
- `AppSettingsProvider` — theme mode, vibration preference

## API Layer

All API logic lives in `lib/services/api_client.dart`. Uses operation-based POST requests with an `op` parameter for legacy endpoints and REST-style endpoints for dashboard data.

Key endpoints:

- `POST /` with `op: login` — authentication
- `POST /` with `op: scan` / `op: scan_verify` — QR verification
- `GET /api/scanner/{role}/events` — dashboard data (role = admin|organizer)
- `POST /api/scanner/*/ticket/scanned-status-change` — toggle ticket status

Auth: Bearer token in Authorization header.

**Note:** Dashboard currently falls back to dummy data (API call is commented out in `dashboard_provider.dart`).

## QR Scan Flow

`QrScannerPage` (camera) → `ScannerProvider.verifyCode()` → `ApiClient.checkQrCode()` (check + verify) → `QrResultScreen` (animated result)

Triple-safety locking prevents duplicate scans: `canDetect` flag + processing lock + 3-second debounce on last scanned code.

## Persistence Keys (SharedPreferences)

All keys are versioned (e.g., `_v1`, `_v2`). Providers handle their own persistence. On logout, history and dashboard cache are cleared.

## Theming & Branding

Dynamic primary color fetched from backend (`/api/scanner/get-basic`), cached for 30 minutes via `BasicService`. Full dark mode support throughout the app, controlled by `AppSettingsProvider`.

## Navigation

Routes defined in `main.dart`: `/splash` → `/login` or `/main` (bottom nav with 3 tabs: Home, Scanner, Profile). Auth gate in `_RootGate` widget controls access.
