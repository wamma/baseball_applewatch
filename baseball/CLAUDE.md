# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Full setup: start backend, update tunnel URL, clean + build Flutter, reinstall pods, open Xcode
make

# Start Docker backend only
docker-compose up -d

# Update cloudflared tunnel URL in lib/config.dart
make update-url

# Reinstall CocoaPods from scratch
cd ios && rm -rf Pods Podfile.lock && pod cache clean --all && pod install

# Flutter
flutter clean && flutter pub get
flutter run

# Full reset (stops Docker, prunes all images/volumes, then rebuilds)
make re
```

## Architecture

This is a **KBO baseball score tracker** with three layers:

### 1. Python Backend (Docker)
- Runs at `localhost:8000` via `docker-compose up -d` (builds from `./python`)
- Exposed publicly via `cloudflared tunnel` — the public URL changes every session
- **Critical**: `lib/config.dart` holds `kBaseUrl` which must match the active tunnel URL. `make update-url` handles this automatically.
- API endpoints used by the app:
  - `GET /games` — all today's KBO games
  - `GET /score?team=<팀명>` — score for a specific team

### 2. Flutter App (`lib/`)
- `lib/config.dart` — single source of truth for backend URL (`kBaseUrl`)
- `lib/main.dart` — 3-tab `BottomNavigationBar`: 마이팀(0) / 전체경기(1) / 마이페이지(2)
- `lib/models/game_info.dart` — `GameInfo` model with `fromJson`
- `lib/screens/all_games_page.dart` — fetches `GET /games`, renders game cards with score/pitcher/status
- `lib/screens/team_status_page.dart` — fetches `GET /score?team=` every 60s with a `Timer.periodic`
- `lib/screens/my_page_screen.dart` — team selection grid; persists to `SharedPreferences` and notifies the iOS widget via `MethodChannel('com.example.baseball/widget')`

### 3. iOS Native Targets (Xcode)
- **MyTeamWidget** (`ios/MyTeamWidget/`) — iPhone home screen widget (small/medium). Fetches score directly from `kServerURL` (hardcoded in `MyTeamWidget.swift`). Refreshes every 5 minutes.
- **MyTeamWidgetWatch** (`ios/MyTeamWidgetWatch/`) — Apple Watch widget (placeholder, not yet implemented).

## Important Caveats

**Two URLs must stay in sync** when the cloudflared tunnel restarts:
1. `lib/config.dart` → `kBaseUrl` (Flutter app)
2. `ios/MyTeamWidget/MyTeamWidget.swift` → `kServerURL` (iOS widget, line 7)

`make update-url` only updates `lib/config.dart`. The Swift constant must be updated manually.

**iOS Widget App Group**: The widget reads the selected team from `UserDefaults(suiteName: "group.com.example.baseball")`. This App Group must be configured in Xcode for both the Runner target and the widget extension.

**Python backend directory**: `docker-compose.yml` builds from `./python` (relative to the `baseball/` folder). If the `python/` directory is missing, Docker build will fail.
