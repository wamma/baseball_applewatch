import asyncio
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from playwright.async_api import async_playwright
from bs4 import BeautifulSoup

app = FastAPI()

# 팀 이름 매핑 - Flutter에서 보내는 이름을 KBO 웹사이트에서 사용하는 이름으로 변환
TEAM_NAME_MAP = {
    "LG트윈스": "LG",
    "LG 트윈스": "LG", 
    "KT위즈": "KT",
    "KT 위즈": "KT",
    "SSG랜더스": "SSG",
    "SSG 랜더스": "SSG",
    "NC다이노스": "NC",
    "NC 다이노스": "NC",
    "KIA타이거즈": "KIA",
    "KIA 타이거즈": "KIA",
    "두산베어스": "두산",
    "두산 베어스": "두산",
    "롯데자이언츠": "롯데",
    "롯데 자이언츠": "롯데",
    "삼성라이온즈": "삼성",
    "삼성 라이온즈": "삼성",
    "한화이글스": "한화",
    "한화 이글스": "한화",
    "키움히어로즈": "키움",
    "키움 히어로즈": "키움"
}

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# HTML 크롤링
async def fetch_kbo_score_html() -> str:
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        await page.goto("https://www.koreabaseball.com/Schedule/GameCenter/Main.aspx")
        await page.wait_for_selector("li.game-cont", timeout=10000)
        html = await page.content()
        await browser.close()
        return html

# HTML 파싱
def parse_all_kbo_games_from_html(html: str):
    soup = BeautifulSoup(html, 'html.parser')
    results = []

    for game in soup.select('li.game-cont'):
        away_team = game.get('away_nm')
        home_team = game.get('home_nm')

        away_logo = game.select_one('.team.away .emb img')
        home_logo = game.select_one('.team.home .emb img')
        away_logo_url = 'https:' + away_logo.get('src') if away_logo else ''
        home_logo_url = 'https:' + home_logo.get('src') if home_logo else ''

        away_pitcher = game.select_one('.team.away .today-pitcher p')
        home_pitcher = game.select_one('.team.home .today-pitcher p')
        away_pitcher_name = away_pitcher.text.strip().replace('선', '').strip() if away_pitcher else ''
        home_pitcher_name = home_pitcher.text.strip().replace('선', '').strip() if home_pitcher else ''

        status_tag = game.select_one('.staus')
        status_text = status_tag.text.strip() if status_tag else "상태 없음"

        item = {
            "away_team": away_team,
            "home_team": home_team,
            "away_logo": away_logo_url,
            "home_logo": home_logo_url,
            "away_pitcher": away_pitcher_name,
            "home_pitcher": home_pitcher_name,
            "status": status_text
        }

        # 점수 있으면 추가
        away_score_tag = game.select_one('.team.away .score')
        home_score_tag = game.select_one('.team.home .score')
        if away_score_tag and home_score_tag:
            try:
                item["away_score"] = int(away_score_tag.text.strip())
                item["home_score"] = int(home_score_tag.text.strip())
            except:
                item["score_error"] = "점수 파싱 실패"

        results.append(item)

    return {"games": results}


# FastAPI 라우터
@app.get("/score")
async def get_score(team: str = "두산"):
    try:
        # 팀 이름 정규화
        normalized_team = TEAM_NAME_MAP.get(team, team)
        print(f"요청된 팀: {team}, 정규화된 팀: {normalized_team}")  # 디버깅용
        
        html = await fetch_kbo_score_html()
        return parse_kbo_score_from_html(html, my_team=normalized_team)
    except Exception as e:
        return {"error": f"서버 오류: {str(e)}"}

@app.get("/games")
async def get_all_games():
    try:
        html = await fetch_kbo_score_html()
        return parse_all_kbo_games_from_html(html)
    except Exception as e:
        return {"error": f"전체 경기 파싱 실패: {str(e)}"}


# 디버깅용 엔드포인트 - 모든 경기 정보 확인
@app.get("/debug/games")
async def debug_games():
    try:
        html = await fetch_kbo_score_html()
        soup = BeautifulSoup(html, 'html.parser')
        games = []
        for game in soup.select('li.game-cont'):
            games.append({
                "away_team": game.get('away_nm'),
                "home_team": game.get('home_nm'),
                "game_html": str(game)[:200] + "..."  # HTML 일부만 표시
            })
        return {"games": games}
    except Exception as e:
        return {"error": str(e)}