# 이닝별 스코어 상세 페이지 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** AllGamesPage에서 경기 카드를 탭하면 이닝별 스코어 상세 페이지로 이동한다.

**Architecture:** Python 백엔드에 `/inning_score` 엔드포인트를 추가해 Playwright로 KBO GameCenter 리뷰 탭을 파싱하고, Flutter `GameDetailPage`에서 이닝 테이블을 표시한다. `game_id`는 `/games` 응답에 포함되어 상세 요청 식별자로 사용된다.

**Tech Stack:** Python FastAPI + Playwright + BeautifulSoup, Flutter/Dart HTTP + Material widgets

---

## File Map

| 파일 | 변경 |
|------|------|
| `python/score_server.py` | `game_id` 추출 추가, `/inning_score` 엔드포인트 신규 |
| `python/test_inning_score.py` | 신규 — 파싱 단위 테스트 |
| `lib/models/game_info.dart` | `gameId` 필드 추가 |
| `lib/screens/all_games_page.dart` | 카드 탭 → `GameDetailPage` 이동 |
| `lib/screens/game_detail_page.dart` | 신규 — 이닝 스코어 상세 페이지 |

---

## Task 1: game_id 속성 탐색

**Files:**
- Modify: `python/score_server.py`

`li.game-cont` 요소의 HTML 속성을 전부 출력하는 디버그 엔드포인트를 추가해 `game_id` 속성명을 확인한다.

- [ ] **Step 1: 디버그 엔드포인트 추가**

`score_server.py` 끝에 추가:

```python
@app.get("/debug/game_attrs")
async def debug_game_attrs():
    try:
        html = await fetch_kbo_score_html()
        soup = BeautifulSoup(html, 'html.parser')
        games = []
        for game in soup.select('li.game-cont'):
            games.append(dict(game.attrs))
        return {"games": games[:3]}  # 첫 3개만
    except Exception as e:
        return {"error": str(e)}
```

- [ ] **Step 2: Docker 서버가 실행 중인지 확인 후 엔드포인트 호출**

```bash
curl http://localhost:8000/debug/game_attrs | python3 -m json.tool
```

응답 예시에서 `game_id`, `game-id`, `gmsc_id` 등 게임 식별자 속성명을 확인한다.

- [ ] **Step 3: 속성명 메모**

응답에서 확인한 game_id 속성명을 아래에 기록한다 (이후 Task에서 사용):

```
# 확인된 game_id 속성명: ___________  (예: "game_id", "gmsc_id")
```

- [ ] **Step 4: 커밋**

```bash
git add python/score_server.py
git commit -m "debug: game_id 속성 탐색용 엔드포인트 추가"
```

---

## Task 2: /games 응답에 game_id 추가

**Files:**
- Modify: `python/score_server.py`

Task 1에서 확인한 속성명을 사용해 `/games` 응답에 `game_id`를 포함시킨다.

- [ ] **Step 1: `parse_all_kbo_games_from_html` 수정**

`score_server.py`의 `item = {...}` 블록에 아래 한 줄 추가 (속성명은 Task 1에서 확인한 값으로 교체):

```python
item["game_id"] = game.get("game_id", "")  # Task 1에서 확인한 속성명으로 교체
```

추가 위치 — 기존 `item` dict 직후:

```python
item = {
    "away_team": away_team,
    "home_team": home_team,
    "away_logo": away_logo_url,
    "home_logo": home_logo_url,
    "away_pitcher": away_pitcher_name,
    "home_pitcher": home_pitcher_name,
    "status": status_text,
    "stadium": stadium_text,
    "game_time": time_text,
    "game_id": game.get("game_id", ""),  # ← 추가 (속성명 교체)
}
```

- [ ] **Step 2: 동작 확인**

```bash
curl http://localhost:8000/games | python3 -m json.tool | grep game_id
```

각 게임에 `game_id` 값이 있는지 확인한다. 빈 문자열이면 Task 1로 돌아가 속성명을 재확인한다.

- [ ] **Step 3: 커밋**

```bash
git add python/score_server.py
git commit -m "feat: /games 응답에 game_id 필드 추가"
```

---

## Task 3: 이닝 스코어 파싱 함수 작성 (TDD)

**Files:**
- Create: `python/test_inning_score.py`
- Modify: `python/score_server.py`

파싱 함수를 먼저 테스트로 정의하고, 그 다음 구현한다.

- [ ] **Step 1: 샘플 HTML 캡처**

KBO 리뷰 탭의 실제 HTML을 캡처한다:

```bash
cd python && python3 - <<'EOF'
import asyncio
from playwright.async_api import async_playwright

async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        # Task 1에서 확인한 game_id 값 사용 (예: 20260329KTLG0)
        await page.goto("https://www.koreabaseball.com/Schedule/GameCenter/Main.aspx?gameId=GAME_ID_HERE")
        await page.wait_for_selector(".review, .inning, table", timeout=10000)
        # 리뷰 탭 클릭 시도
        try:
            await page.click("text=리뷰")
            await page.wait_for_timeout(2000)
        except:
            pass
        html = await page.content()
        await browser.close()
        with open("/tmp/review_sample.html", "w") as f:
            f.write(html)
        print("HTML 저장 완료: /tmp/review_sample.html")

asyncio.run(main())
EOF
```

저장된 HTML에서 이닝 테이블 선택자와 구조를 확인한다:

```bash
python3 -c "
from bs4 import BeautifulSoup
html = open('/tmp/review_sample.html').read()
soup = BeautifulSoup(html, 'html.parser')
# 이닝 테이블 찾기
for tag in ['table', '.tbl', '.inning-score', '.review-score']:
    found = soup.select(tag)
    if found:
        print(f'선택자 {tag}: {len(found)}개')
        print(str(found[0])[:500])
        break
"
```

- [ ] **Step 2: 테스트 파일 작성**

확인한 HTML 구조를 바탕으로 `python/test_inning_score.py` 작성:

```python
# python/test_inning_score.py
from bs4 import BeautifulSoup
from score_server import parse_inning_score_from_html

# 이닝 테이블 샘플 HTML — 실제 구조에 맞게 수정 필요
SAMPLE_HTML = """
<table class="tbl">
  <thead>
    <tr>
      <th>TEAM</th><th>1</th><th>2</th><th>3</th><th>4</th>
      <th>5</th><th>6</th><th>7</th><th>8</th><th>9</th>
      <th>R</th><th>H</th><th>E</th><th>B</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>KT</td><td>3</td><td>0</td><td>0</td><td>0</td>
      <td>2</td><td>0</td><td>0</td><td>1</td><td>-</td>
      <td>6</td><td>11</td><td>1</td><td>6</td>
    </tr>
    <tr>
      <td>LG</td><td>0</td><td>0</td><td>3</td><td>2</td>
      <td>0</td><td>0</td><td>0</td><td>0</td><td>-</td>
      <td>5</td><td>10</td><td>0</td><td>6</td>
    </tr>
  </tbody>
</table>
"""


def test_parse_inning_score_returns_both_teams():
    result = parse_inning_score_from_html(SAMPLE_HTML)
    assert "away_innings" in result
    assert "home_innings" in result


def test_parse_inning_score_away_innings():
    result = parse_inning_score_from_html(SAMPLE_HTML)
    assert result["away_innings"] == [3, 0, 0, 0, 2, 0, 0, 1, None]


def test_parse_inning_score_home_innings():
    result = parse_inning_score_from_html(SAMPLE_HTML)
    assert result["home_innings"] == [0, 0, 3, 2, 0, 0, 0, 0, None]


def test_parse_inning_score_totals():
    result = parse_inning_score_from_html(SAMPLE_HTML)
    assert result["away_totals"] == {"R": 6, "H": 11, "E": 1, "B": 6}
    assert result["home_totals"] == {"R": 5, "H": 10, "E": 0, "B": 6}


def test_parse_inning_score_team_names():
    result = parse_inning_score_from_html(SAMPLE_HTML)
    assert result["away_team"] == "KT"
    assert result["home_team"] == "LG"
```

> **주의:** `SAMPLE_HTML`은 Step 1에서 확인한 실제 HTML 구조에 맞게 수정한다.

- [ ] **Step 3: 테스트 실패 확인**

```bash
cd python && python3 -m pytest test_inning_score.py -v
```

Expected: `ImportError` 또는 `FAILED` — `parse_inning_score_from_html` 미구현

- [ ] **Step 4: `parse_inning_score_from_html` 구현**

`score_server.py`에 추가 (기존 함수들 아래):

```python
def parse_inning_score_from_html(html: str) -> dict:
    soup = BeautifulSoup(html, 'html.parser')

    # 이닝 테이블 찾기 — 실제 선택자로 교체 필요
    table = soup.select_one('table.tbl') or soup.select_one('table')
    if not table:
        return {"error": "이닝 테이블을 찾을 수 없습니다"}

    rows = table.select('tbody tr')
    if len(rows) < 2:
        return {"error": "이닝 데이터 행이 부족합니다"}

    def parse_row(row):
        cells = [td.text.strip() for td in row.select('td')]
        if len(cells) < 5:
            return None, [], {}
        team_name = cells[0]
        # 마지막 4개: R, H, E, B
        totals_raw = cells[-4:]
        inning_cells = cells[1:-4]
        innings = []
        for c in inning_cells:
            if c == '-' or c == '':
                innings.append(None)
            else:
                try:
                    innings.append(int(c))
                except ValueError:
                    innings.append(None)
        try:
            totals = {
                "R": int(totals_raw[0]),
                "H": int(totals_raw[1]),
                "E": int(totals_raw[2]),
                "B": int(totals_raw[3]),
            }
        except (ValueError, IndexError):
            totals = {"R": 0, "H": 0, "E": 0, "B": 0}
        return team_name, innings, totals

    away_team, away_innings, away_totals = parse_row(rows[0])
    home_team, home_innings, home_totals = parse_row(rows[1])

    return {
        "away_team": away_team,
        "home_team": home_team,
        "away_innings": away_innings,
        "home_innings": home_innings,
        "away_totals": away_totals,
        "home_totals": home_totals,
        "inning_count": len(away_innings),
    }
```

- [ ] **Step 5: 테스트 통과 확인**

```bash
cd python && python3 -m pytest test_inning_score.py -v
```

Expected: 5개 모두 PASSED

- [ ] **Step 6: 커밋**

```bash
git add python/test_inning_score.py python/score_server.py
git commit -m "feat: 이닝 스코어 HTML 파싱 함수 추가 (TDD)"
```

---

## Task 4: /inning_score 엔드포인트 추가

**Files:**
- Modify: `python/score_server.py`

- [ ] **Step 1: 엔드포인트 추가**

`score_server.py`의 라우터 섹션에 추가:

```python
@app.get("/inning_score")
async def get_inning_score(game_id: str):
    if not game_id:
        return {"error": "game_id가 필요합니다"}
    try:
        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)
            page = await browser.new_page()
            url = f"https://www.koreabaseball.com/Schedule/GameCenter/Main.aspx?gameId={game_id}"
            await page.goto(url)
            # 리뷰 탭 클릭
            try:
                await page.click("text=리뷰")
                await page.wait_for_timeout(2000)
            except Exception:
                pass
            html = await page.content()
            await browser.close()
        return parse_inning_score_from_html(html)
    except Exception as e:
        return {"error": f"이닝 스코어 파싱 실패: {str(e)}"}
```

- [ ] **Step 2: 엔드포인트 동작 확인**

Task 1에서 확인한 실제 game_id 값으로 테스트:

```bash
# game_id 예시 — 실제 값으로 교체
curl "http://localhost:8000/inning_score?game_id=ACTUAL_GAME_ID" | python3 -m json.tool
```

Expected: `away_innings`, `home_innings`, `away_totals`, `home_totals` 포함 JSON

- [ ] **Step 3: 커밋**

```bash
git add python/score_server.py
git commit -m "feat: /inning_score 엔드포인트 추가"
```

---

## Task 5: GameInfo 모델에 gameId 추가

**Files:**
- Modify: `lib/models/game_info.dart`

- [ ] **Step 1: `gameId` 필드 추가**

`lib/models/game_info.dart`를 다음과 같이 수정:

```dart
class GameInfo {
  final String awayTeam;
  final String homeTeam;
  final String awayLogo;
  final String homeLogo;
  final String awayPitcher;
  final String homePitcher;
  final String status;
  final String? awayScore;
  final String? homeScore;
  final String stadium;
  final String gameTime;
  final String gameId; // ← 추가

  GameInfo({
    required this.awayTeam,
    required this.homeTeam,
    required this.awayLogo,
    required this.homeLogo,
    required this.awayPitcher,
    required this.homePitcher,
    required this.status,
    this.awayScore,
    this.homeScore,
    this.stadium = '',
    this.gameTime = '',
    this.gameId = '', // ← 추가
  });

  factory GameInfo.fromJson(Map<String, dynamic> json) {
    return GameInfo(
      awayTeam: json['away_team'] ?? '',
      homeTeam: json['home_team'] ?? '',
      awayLogo: json['away_logo'] ?? '',
      homeLogo: json['home_logo'] ?? '',
      awayPitcher: json['away_pitcher'] ?? '',
      homePitcher: json['home_pitcher'] ?? '',
      status: json['status'] ?? '',
      awayScore: json['away_score']?.toString(),
      homeScore: json['home_score']?.toString(),
      stadium: json['stadium'] ?? '',
      gameTime: json['game_time'] ?? '',
      gameId: json['game_id'] ?? '', // ← 추가
    );
  }
}
```

- [ ] **Step 2: Flutter 빌드 오류 없는지 확인**

```bash
cd /Users/heongjunpark/Desktop/hyungjup/baseball_applewatch/baseball
flutter analyze lib/models/game_info.dart
```

Expected: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/models/game_info.dart
git commit -m "feat: GameInfo 모델에 gameId 필드 추가"
```

---

## Task 6: AllGamesPage 카드 탭 인터랙션 추가

**Files:**
- Modify: `lib/screens/all_games_page.dart`

- [ ] **Step 1: import 추가**

`all_games_page.dart` 상단 import 섹션에 추가:

```dart
import 'game_detail_page.dart';
```

- [ ] **Step 2: `_buildGameCard`에 InkWell 추가**

기존 `_buildGameCard`에서 `Card(...)` 전체를 `InkWell`로 감싼다:

```dart
Widget _buildGameCard(GameInfo game) {
  final hasScore = game.awayScore != null && game.homeScore != null;
  final awayPitcher = _parsePitcher(game.awayPitcher);
  final homePitcher = _parsePitcher(game.homePitcher);

  return InkWell(
    onTap: game.gameId.isEmpty
        ? null
        : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameDetailPage(game: game),
              ),
            );
          },
    borderRadius: BorderRadius.circular(12),
    child: Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1.5,
      shadowColor: Colors.black.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            // 스코어 행
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _logo(game.awayLogo, 44),
                    const SizedBox(width: 8),
                    if (hasScore)
                      Text(
                        game.awayScore!,
                        style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A)),
                      ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusBgColor(game.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    game.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(game.status),
                    ),
                  ),
                ),
                Row(
                  children: [
                    if (hasScore)
                      Text(
                        game.homeScore!,
                        style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A)),
                      ),
                    const SizedBox(width: 8),
                    _logo(game.homeLogo, 44),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(awayPitcher['name']!,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF666666))),
                    _pitcherBadge(awayPitcher['badge']!),
                  ],
                ),
                const Text('vs',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _pitcherBadge(homePitcher['badge']!),
                    Text(homePitcher['name']!,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF666666))),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
```

- [ ] **Step 3: Flutter analyze 실행**

```bash
flutter analyze lib/screens/all_games_page.dart
```

Expected: `No issues found!` (GameDetailPage import 오류가 나면 Task 7 먼저 진행)

- [ ] **Step 4: 커밋**

```bash
git add lib/screens/all_games_page.dart
git commit -m "feat: AllGamesPage 카드 탭 시 GameDetailPage 이동"
```

---

## Task 7: GameDetailPage 구현

**Files:**
- Create: `lib/screens/game_detail_page.dart`

- [ ] **Step 1: `game_detail_page.dart` 생성**

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/game_info.dart';
import '../config.dart';

class GameDetailPage extends StatefulWidget {
  final GameInfo game;
  const GameDetailPage({Key? key, required this.game}) : super(key: key);

  @override
  _GameDetailPageState createState() => _GameDetailPageState();
}

class _GameDetailPageState extends State<GameDetailPage> {
  Map<String, dynamic>? _inningData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInningScore();
  }

  Future<void> _fetchInningScore() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse(
          "$kBaseUrl/inning_score?game_id=${widget.game.gameId}");
      final response = await http.get(uri);
      if (response.statusCode != 200) throw Exception("서버 응답 오류");
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data['error'] != null) throw Exception(data['error']);
      setState(() {
        _inningData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${game.awayTeam} vs ${game.homeTeam}',
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildScoreHeader(game),
            const SizedBox(height: 12),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreHeader(GameInfo game) {
    final hasScore = game.awayScore != null && game.homeScore != null;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _teamColumn(game.awayLogo, game.awayTeam),
          if (hasScore)
            Text(
              '${game.awayScore}  :  ${game.homeScore}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            )
          else
            Text(
              game.status,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          _teamColumn(game.homeLogo, game.homeTeam),
        ],
      ),
    );
  }

  Widget _teamColumn(String logoUrl, String teamName) {
    return Column(
      children: [
        logoUrl.isEmpty
            ? const Icon(Icons.sports_baseball, size: 40, color: Colors.grey)
            : Image.network(logoUrl,
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.sports_baseball,
                    size: 40,
                    color: Colors.grey)),
        const SizedBox(height: 4),
        Text(teamName,
            style: const TextStyle(fontSize: 13, color: Color(0xFF444444))),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.grey, size: 48),
            const SizedBox(height: 12),
            Text('데이터를 불러올 수 없습니다',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }
    if (_inningData == null) return const SizedBox.shrink();

    final status = widget.game.status;
    if (status.contains('예정')) {
      return const Center(
        child: Text('아직 경기 전입니다',
            style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    return _buildInningTable();
  }

  Widget _buildInningTable() {
    final awayInnings = List<dynamic>.from(_inningData!['away_innings'] ?? []);
    final homeInnings = List<dynamic>.from(_inningData!['home_innings'] ?? []);
    final awayTotals = Map<String, dynamic>.from(_inningData!['away_totals'] ?? {});
    final homeTotals = Map<String, dynamic>.from(_inningData!['home_totals'] ?? {});
    final awayTeam = _inningData!['away_team'] ?? widget.game.awayTeam;
    final homeTeam = _inningData!['home_team'] ?? widget.game.homeTeam;
    final inningCount = awayInnings.length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey[200]!, width: 1),
            verticalInside: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          children: [
            _headerRow(inningCount),
            _dataRow(awayTeam, awayInnings, awayTotals, isAway: true),
            _dataRow(homeTeam, homeInnings, homeTotals, isAway: false),
          ],
        ),
      ),
    );
  }

  TableRow _headerRow(int inningCount) {
    final cells = <Widget>[_headerCell('TEAM')];
    for (int i = 1; i <= inningCount; i++) {
      cells.add(_headerCell('$i'));
    }
    for (final label in ['R', 'H', 'E', 'B']) {
      cells.add(_headerCell(label, bold: true));
    }
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xFF1A237E)),
      children: cells,
    );
  }

  TableRow _dataRow(String team, List<dynamic> innings,
      Map<String, dynamic> totals, {required bool isAway}) {
    final cells = <Widget>[_dataCell(team, bold: true)];
    for (final val in innings) {
      cells.add(_dataCell(val == null ? '-' : '$val'));
    }
    for (final key in ['R', 'H', 'E', 'B']) {
      cells.add(_dataCell('${totals[key] ?? '-'}',
          bold: key == 'R', highlight: key == 'R'));
    }
    return TableRow(children: cells);
  }

  Widget _headerCell(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _dataCell(String text, {bool bold = false, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: highlight ? const Color(0xFFD32F2F) : const Color(0xFF1A1A1A),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Flutter analyze 실행**

```bash
flutter analyze lib/screens/game_detail_page.dart lib/screens/all_games_page.dart
```

Expected: `No issues found!`

- [ ] **Step 3: 시뮬레이터에서 실행 및 탭 동작 확인**

```bash
flutter run
```

전체경기 탭 → 종료된 경기 카드 탭 → `GameDetailPage` 이동 → 이닝 테이블 표시 확인

- [ ] **Step 4: 커밋**

```bash
git add lib/screens/game_detail_page.dart lib/screens/all_games_page.dart
git commit -m "feat: GameDetailPage 이닝 스코어 상세 페이지 구현"
```

---

## 전체 테스트 체크리스트

- [ ] `/debug/game_attrs` 응답에서 game_id 속성 확인
- [ ] `/games` 응답 각 게임에 `game_id` 값 존재
- [ ] `/inning_score?game_id=XXXX` 응답에 이닝 배열과 R/H/E/B 합계 포함
- [ ] Python 단위 테스트 5개 PASSED
- [ ] AllGamesPage 카드 탭 시 GameDetailPage 이동
- [ ] 종료 경기: 이닝 테이블 정상 표시
- [ ] 예정 경기: "아직 경기 전입니다" 표시
- [ ] 이닝 수가 9를 초과하면 연장 이닝 컬럼도 표시
