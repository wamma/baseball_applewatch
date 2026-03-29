# 이닝별 스코어 상세 페이지 설계

**날짜**: 2026-03-30
**범위**: AllGamesPage 게임 카드 탭 → 이닝 스코어 상세 페이지

---

## 목표

전체 경기 보기 화면에서 각 경기 카드를 탭하면, 해당 경기의 이닝별 득점 현황(리뷰)을 새 페이지에서 보여준다.

---

## 백엔드 설계 (`python/score_server.py`)

### 1. `/games` 응답에 `game_id` 추가

`parse_all_kbo_games_from_html` 함수에서 `li.game-cont` 속성의 `game_id`(또는 유사 속성)를 추출해 각 게임 dict에 포함한다.

```python
item["game_id"] = game.get("game_id", "")
```

### 2. 새 엔드포인트: `GET /inning_score`

**파라미터**: `game_id` (예: `20260329KTLG0`)

**동작**:
1. Playwright로 `https://www.koreabaseball.com/Schedule/GameCenter/Main.aspx?gameId={game_id}` 로드
2. "리뷰" 탭 클릭 (선택자 확인 필요)
3. 이닝 스코어 테이블 파싱

**응답 형태**:
```json
{
  "away_team": "KT",
  "home_team": "LG",
  "away_innings": [3, 0, 0, 0, 2, 0, 0, 1, 0],
  "home_innings": [0, 0, 3, 2, 0, 0, 0, 0, 0],
  "away_totals": {"R": 6, "H": 11, "E": 1, "B": 6},
  "home_totals": {"R": 5, "H": 10, "E": 0, "B": 6},
  "inning_count": 9
}
```

- 미진행 이닝은 `null` 또는 `"-"`으로 표현
- 연장전이면 `inning_count`가 9 초과
- 경기 전(예정)이면 `{"status": "예정"}` 반환

---

## Flutter 설계

### 변경 파일

#### `lib/models/game_info.dart`
- `gameId` 필드 추가 (`String`, 기본값 `''`)
- `fromJson`에서 `json['game_id']` 파싱

#### `lib/screens/all_games_page.dart`
- `_buildGameCard`에서 카드를 `InkWell`로 감싸기
- 탭 시 `Navigator.push` → `GameDetailPage(game: game)`

### 신규 파일

#### `lib/screens/game_detail_page.dart`

**레이아웃**:
```
[ AppBar: "어웨이 vs 홈" ]
[ 로고 + 팀명 | 최종스코어 | 로고 + 팀명 ]
[ 이닝 스코어 테이블 (가로 스크롤) ]

TEAM | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | R | H | E | B
KT   | 3 | 0 | 0 | 0 | 2 | 0 | 0 | 1 | - | 6 |11 | 1 | 6
LG   | 0 | 0 | 3 | 2 | 0 | 0 | 0 | 0 | - | 5 |10 | 0 | 6
```

**상태 처리**:
- 로딩 중: `CircularProgressIndicator`
- 경기 예정: "아직 경기 전입니다" 텍스트
- 오류: "데이터를 불러올 수 없습니다" 텍스트
- 경기 중(진행): 현재까지 이닝만 표시, 미진행 이닝은 `-`

**API 호출**: `GET $kBaseUrl/inning_score?game_id={game.gameId}`

---

## 데이터 흐름

```
사용자 탭
  ↓
AllGamesPage → Navigator.push(GameDetailPage)
  ↓
GameDetailPage.initState() → GET /inning_score?game_id=XXXX
  ↓
score_server.py → Playwright → koreabaseball.com GameCenter 리뷰 탭
  ↓
이닝 테이블 파싱 → JSON 응답
  ↓
GameDetailPage → SingleChildScrollView(scrollDirection: horizontal) 테이블 렌더링
```

---

## 범위 외 (이번 구현에서 제외)

- 키플레이어 탭 데이터
- 하이라이트 영상
- 이닝별 이벤트 상세 (득점 상황 등)
