# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# 새 머신에서 최초 1회 실행 (xcode-select + xcodeproj 패치)
make setup

# 매일 시작할 때: Docker + tunnel + Flutter + CocoaPods + Xcode 열기
make

# tunnel URL만 갱신 (서버 재시작 시)
make update-url

# Flutter만 재빌드
flutter clean && flutter pub get && flutter run

# Full reset (Docker 포함 전체 초기화)
make re
```

## 머신 간 이동 시 체크리스트

```bash
# 1. 최신 코드 동기화
git pull

# 2. 최초 1회만 — xcode-select 설정 (머신당 한 번)
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# 3. 매번 — 전체 빌드 (xcodeproj 패치 포함)
make
```

**Xcode 수동 설정 불필요** — App Group, entitlements, 타겟 설정 모두 git에 포함됨

## Architecture

This is a **KBO baseball score tracker** with three layers:

### 1. Python Backend (Docker)
- Runs at `localhost:8000` via `docker-compose up -d`
- Exposed publicly via `cloudflared tunnel` — URL changes every session
- `make update-url` → `lib/config.dart` + `ios/MyTeamWidget/MyTeamWidget.swift` 동시 갱신

### 2. Flutter App (`lib/`)
- `lib/config.dart` — 서버 URL 단일 소스 (`kBaseUrl`)
- `lib/main.dart` — 3-tab: 마이팀(0) / 전체경기(1) / 마이페이지(2)
- `lib/screens/my_page_screen.dart` — 팀 선택 → SharedPreferences + MethodChannel(`com.example.baseball/widget`) → iOS 위젯 갱신

### 3. iOS Native Targets (Xcode)
- **MyTeamWidgetExtension** (`ios/MyTeamWidget/`) — 홈화면(small/medium) + 잠금화면(circular/rectangular/inline) 위젯
  - `kServerURL` — `make update-url`로 자동 갱신
  - App Group `group.baseball.myteam`으로 선택팀 공유
- **MyTeamWidgetWatch** (`ios/MyTeamWidgetWatch/`) — Apple Watch 위젯 (미구현)

## Known Issues

- **CocoaPods + Xcode 26**: xcodeproj 1.27.0이 object version 70 미지원 → `make setup`이 자동 패치
- **CocoaPods 업그레이드 시**: 패치가 덮어씌워질 수 있으므로 `make setup` 재실행
