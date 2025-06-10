import asyncio
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from playwright.async_api import async_playwright
from bs4 import BeautifulSoup

app = FastAPI()

TEAM_CODE_MAP = {
    "doosan": "두산",
    "lotte": "롯데",
    "lg": "LG",
    "ssg": "SSG",
    "nc": "NC",
    "kt": "KT",
    "kia": "KIA",
    "samsung": "삼성",
    "hanwha": "한화",
    "kiwoom": "키움",
}


# (선택) Flutter 앱에서 CORS 문제 방지
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Flutter 테스트용이므로 전체 허용
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ 1. HTML 가져오기
async def fetch_kbo_score_html() -> str:
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        url = "https://www.koreabaseball.com/Schedule/GameCenter/Main.aspx"
        await page.goto(url)
        await page.wait_for_selector("li.game-cont", timeout=10000)
        html = await page.content()
        await browser.close()
        return html

# ✅ 2. HTML 파싱
def parse_kbo_score_from_html(html: str, my_team='두산'):
    soup = BeautifulSoup(html, 'html.parser')
    game_list = soup.select('li.game-cont')
    for game in game_list:
        away_team = game.get('away_nm')
        home_team = game.get('home_nm')
        if my_team in (away_team, home_team):
            away_score_tag = game.select_one('.team.away .score')
            home_score_tag = game.select_one('.team.home .score')
            if not away_score_tag or not home_score_tag:
                return {'error': '점수 정보가 없습니다.'}
            try:
                away_score = int(away_score_tag.text.strip())
                home_score = int(home_score_tag.text.strip())
                result = {
                    'my_team': my_team,
                    'opponent': home_team if away_team == my_team else away_team,
                    'my_score': away_score if away_team == my_team else home_score,
                    'opponent_score': home_score if away_team == my_team else away_score,
                }
                result['status'] = (
                    'WIN' if result['my_score'] > result['opponent_score']
                    else 'LOSE' if result['my_score'] < result['opponent_score']
                    else 'DRAW'
                )
                return result
            except Exception as e:
                return {'error': f'점수 파싱 중 오류: {str(e)}'}
    return {'error': f'{my_team}의 경기를 찾을 수 없습니다.'}

# ✅ 3. FastAPI 라우터
@app.get("/score")
async def get_score(team: str = "doosan"):
    try:
        html = await fetch_kbo_score_html()
        html_team_name = TEAM_CODE_MAP.get(team.lower(), team)
        result = parse_kbo_score_from_html(html, my_team=html_team_name)
        return result
    except Exception as e:
        return {"error": str(e)}

