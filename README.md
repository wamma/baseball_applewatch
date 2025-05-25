# Baseball AppleWatch

이 프로젝트는 애플워치에서 내가 설정한 팀의 경기 결과를 실시간으로 확인하기 위한 스켈레톤입니다.

## 개요
1. 사용자가 `TeamSettings`를 통해 나의 팀을 설정합니다.
2. `ScoreViewModel`이 주기적으로 야구 스코어 API를 호출하여 현재 점수를 가져옵니다. (실제 API 연동은 추후 구현합니다)
3. 스코어를 비교하여 이기면 `win`, 비기면 `draw`, 지면 `lose` 문구를 `ContentView`에서 표시합니다.

## 구조
- `BaseballWatchApp.swift` : watchOS 앱의 진입점.
- `ContentView.swift` : 현재 경기 상태를 보여주는 화면.
- `ScoreViewModel.swift` : 네트워크 호출 및 상태 갱신 로직.
- `TeamSettings.swift` : 사용자가 선택한 팀을 저장하는 유틸리티.

현재는 기본적인 틀만 구현되어 있으며, 실제 스코어를 가져오는 부분과 사용자 인터페이스 개선은 추가 작업이 필요합니다.

