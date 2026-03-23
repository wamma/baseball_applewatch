# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# 새 머신에서 최초 1회 (xcode-select 설정 + xcodeproj Xcode 26 패치)
make setup

# 매일 시작할 때: Docker + cloudflare tunnel + flutter clean/pub get + pod install + Xcode 열기
make

# tunnel URL만 갱신 (서버 재시작 시) — config.dart, MyTeamWidget.swift, MyTeamWidgetWatch.swift 동시 업데이트
make update-url

# Flutter만 재빌드
flutter clean && flutter pub get && flutter run

# Full reset (Docker 이미지까지 전체 삭제 후 재빌드)
make re
```

## 머신 간 이동 체크리스트

```bash
git pull
make setup   # 최초 1회 (머신당 한 번)
make         # 매번 실행
```

**Xcode 수동 설정 불필요** — App Group, entitlements, 모든 타겟 설정이 `project.pbxproj`에 포함되어 git으로 공유됨. Signing(인증서)만 각 기기의 Apple ID로 자동 처리.

## Architecture

KBO 야구 경기 결과 트래커. 세 레이어로 구성.

### 1. Python Backend (`python/score_server.py`)
- FastAPI + Playwright + BeautifulSoup으로 `koreabaseball.com` 크롤링
- Docker로 실행 (`localhost:8000`), cloudflared tunnel로 외부 노출
- **URL은 세션마다 바뀜** → `make update-url`로 세 파일 동시 갱신
- 엔드포인트:
  - `GET /score?team=두산` — 특정 팀 오늘 경기 결과 (위젯용)
  - `GET /games` — 오늘 전체 경기 목록 (Flutter 전체경기 탭용)
  - `GET /debug/games` — 크롤링 디버깅용
- 팀 이름 정규화: `TEAM_NAME_MAP`이 Flutter 전체 팀명 → KBO 사이트 약칭으로 변환

### 2. Flutter App (`lib/`)
- **`lib/config.dart`** — `kBaseUrl` 단일 소스. `make update-url`이 sed로 자동 교체
- **`lib/main.dart`** — `HomeScreen` (IndexedStack 3탭):
  - 탭 0 `TeamStatusPage`: 선택한 팀의 오늘 경기 상세
  - 탭 1 `AllGamesPage`: 전체 경기 목록 (기본 탭)
  - 탭 2 `MyPageScreen`: 팀 선택 UI
- **팀 선택 흐름**: `MyPageScreen._selectTeam()` → SharedPreferences 저장 → MethodChannel `com.example.baseball/widget`으로 `saveTeam` 호출 → AppDelegate가 App Group에 저장 → WidgetCenter.reloadAllTimelines()

### 3. iOS Native (`ios/`)

#### AppDelegate (`ios/Runner/AppDelegate.swift`)
- MethodChannel `com.example.baseball/widget` 핸들러 등록
- `saveTeam` 수신 시: `UserDefaults(suiteName: "group.baseball.myteam")` 저장 + 위젯 갱신

#### MyTeamWidgetExtension (`ios/MyTeamWidget/`)
- 홈화면(small/medium) + 잠금화면(circular/rectangular/inline) 위젯
- App Group `group.baseball.myteam`에서 `myTeam` 읽어 `/score` API 호출
- `kServerURL` — `make update-url`로 자동 갱신

#### MyTeamWidgetWatchExtension (`ios/MyTeamWidgetWatch/`)
- Apple Watch Smart Stack 위젯 (rectangular/circular/inline)
- 동일한 App Group + 동일한 `/score` API 사용
- `kServerURL` — `make update-url`로 자동 갱신
- **배포**: scheme → `MyTeamWidgetWatchExtension` → Apple Watch 기기 선택 → Cmd+R

### 데이터 흐름 요약
```
koreabaseball.com
    ↓ Playwright 크롤링
score_server.py (localhost:8000)
    ↓ cloudflared tunnel
Flutter AllGamesPage / TeamStatusPage
    ↓ (팀 선택 시)
AppDelegate → UserDefaults(App Group)
    ↓
MyTeamWidgetExtension (iPhone 위젯)
MyTeamWidgetWatchExtension (Watch 위젯)
```

## 핵심 상수

| 상수 | 위치 | 값 |
|------|------|----|
| `kBaseUrl` | `lib/config.dart` | cloudflare tunnel URL |
| `kServerURL` | `ios/MyTeamWidget/MyTeamWidget.swift` | 동일 URL |
| `kServerURL` | `ios/MyTeamWidgetWatch/MyTeamWidgetWatch.swift` | 동일 URL |
| `kAppGroupID` | AppDelegate, 각 위젯 Swift | `group.baseball.myteam` |
| MethodChannel | Flutter/AppDelegate | `com.example.baseball/widget` |

## Known Issues

- **CocoaPods + Xcode 26**: xcodeproj 1.27.0이 object version 70 미지원 → `make setup`이 자동 패치. CocoaPods 업그레이드 시 재실행 필요
- **Watch 위젯 배포**: watchOS 익스텐션은 iPhone 앱 Embed Foundation Extensions에 넣으면 안 됨 (iOS SDK로 컴파일 시도). Watch 기기에 직접 배포해야 함
