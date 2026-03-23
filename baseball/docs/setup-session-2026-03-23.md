# Apple Watch Widget 세팅 세션 — 2026-03-23

## 목표
Apple Watch Smart Stack에 KBO 경기 결과 위젯 표시

---

## 작업 내역

### 1. 현재까지 변경사항 커밋
커밋: `feat: Apple Watch 위젯 구현, 잠금화면 위젯 추가, make setup 자동화`

포함 내용:
- `MyTeamWidgetWatch.swift`: KBO 경기 데이터 표시 (rectangular/circular/inline)
- `MyTeamWidgetBundle.swift`: Control/LiveActivity 타겟 제거 (Watch 오작동 방지)
- `Makefile`: setup 타겟 추가 (xcode-select + xcodeproj Xcode 26 패치 자동화)
- `Makefile`: update-url이 MyTeamWidgetWatch.swift도 동시 업데이트
- `CLAUDE.md`: 머신 간 이동 체크리스트 및 전체 아키텍처 정리

---

### 2. Xcode에서 MyTeamWidgetWatchExtension 타겟 추가

#### 타겟 생성
- File → New → Target → **watchOS** 탭 → **Widget Extension**
- Product Name: `MyTeamWidgetWatch`
- Organization Identifier: `com.example.baseball`
- Bundle Identifier (자동): `com.example.baseball.MyTeamWidgetWatch`
- Include Control: **체크 해제**
- Include Configuration App Intent: **체크 해제**
- Finish → Activate

#### App Group 추가
- TARGETS → MyTeamWidgetWatchExtension → Signing & Capabilities
- `+ Capability` → App Groups
- `group.baseball.myteam` 체크

#### 기존 코드로 파일 교체
Xcode가 자동 생성한 템플릿을 기존 KBO 구현체로 교체:
- `ios/MyTeamWidgetWatch/MyTeamWidgetWatch.swift` → KBO 데이터 fetch 구현
- `ios/MyTeamWidgetWatch/MyTeamWidgetWatchBundle.swift` → 그대로 사용 (MyTeamWidgetWatch()만 포함)

---

### 3. 빌드 에러 및 해결

#### 에러 1: PIF transfer session
```
Could not compute dependency graph: MsgHandlingError(message: "unable to initiate PIF transfer session")
```
**원인**: Xcode 내부 상태 충돌
**해결**:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```
Xcode 재시작 → Cmd+Shift+K → Cmd+R

---

#### 에러 2: #Preview watchOS 10.0 이상에서만 사용 가능
```
error: 'Preview(_:as:widget:timeline:)' is only available in watchOS 10.0 or newer
```
**원인**: Minimum Deployment가 watchOS 9.6인데 `#Preview` 매크로는 10.0+ 필요
**해결**: `MyTeamWidgetWatch.swift` 파일 하단의 `#Preview` 블록 제거

---

#### 에러 3: watchOS 익스텐션을 iOS Embed Foundation Extensions에 넣으면 안 됨
```
error: 'Timeline' is only available in iOS 14.0 or newer
error: 'widgetFamily' is only available in iOS 14.0 or newer
...
```
**원인**: watchOS 타겟을 Runner(iPhone)의 Embed Foundation Extensions에 추가하면
iOS SDK로 컴파일 시도 → watchOS 전용 API들이 "iOS에서 사용 불가" 에러 발생
**해결**:
- Runner → Build Phases → Embed Foundation Extensions에서 `MyTeamWidgetWatchExtension` 제거
- Watch에 직접 배포: scheme → MyTeamWidgetWatchExtension → Apple Watch 기기 선택 → Cmd+R

---

### 4. Watch 위젯 배포 방법

#### 개발 중 (현재)
scheme → `MyTeamWidgetWatchExtension` → 기기: **Apple Watch** → Cmd+R

#### 프로덕션 (향후)
iPhone 앱 설치 시 Watch 위젯도 함께 설치되게 하려면:
1. WatchKit App 타겟 추가 (Runner에 embed)
2. WatchKit App 안에 MyTeamWidgetWatchExtension embed
→ 현재는 Watch 직접 배포로 동작 확인 후 추후 작업 예정

---

## 현재 Xcode 타겟 구성

| 타겟 | 플랫폼 | Bundle ID |
|------|--------|-----------|
| Runner | iOS | com.example.baseball |
| RunnerTests | iOS | com.example.baseball.RunnerTests |
| MyTeamWidgetExtension | iOS | com.example.baseball.MyTeamWidget |
| MyTeamWidgetWatchExtension | watchOS | com.example.baseball.MyTeamWidgetWatch |

---

## 핵심 설정값

| 항목 | 값 |
|------|-----|
| App Group | `group.baseball.myteam` |
| Organization Identifier | `com.example.baseball` |
| Watch Min Deployment | watchOS 9.6 |

---

## 다음 작업
- [ ] Watch 직접 배포 후 Smart Stack에서 위젯 동작 확인
- [ ] 프로덕션 배포를 위한 WatchKit App 타겟 추가 (선택)
- [ ] project.pbxproj 포함 git commit (Xcode 설정 머신 간 공유)
