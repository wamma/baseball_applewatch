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
    "hanhwa": "한화",
    "kiwoom": "키움"
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
def parse_kbo_score_from_html(html: str, my_team='두산'):
    soup = BeautifulSoup(html, 'html.parser')
    for game in soup.select('li.game-cont'):
        away_team = game.get('away_nm')
        home_team = game.get('home_nm')
        if my_team not in (away_team, home_team):
            continue

        is_away = my_team == away_team
        opponent = home_team if is_away else away_team

        away_logo = game.select_one('.team.away .emb img')
        home_logo = game.select_one('.team.home .emb img')
        away_logo_url = 'https:' + away_logo.get('src') if away_logo else ''
        home_logo_url = 'https:' + home_logo.get('src') if home_logo else ''
        my_logo = away_logo_url if is_away else home_logo_url
        opponent_logo = home_logo_url if is_away else away_logo_url

        away_pitcher = game.select_one('.team.away .today-pitcher p')
        home_pitcher = game.select_one('.team.home .today-pitcher p')
        away_pitcher_name = away_pitcher.text.strip().replace('선', '').strip() if away_pitcher else ''
        home_pitcher_name = home_pitcher.text.strip().replace('선', '').strip() if home_pitcher else ''
        my_pitcher = away_pitcher_name if is_away else home_pitcher_name
        opponent_pitcher = home_pitcher_name if is_away else away_pitcher_name

        # 기본 정보 구성
        result = {
            "my_team": my_team,
            "opponent": opponent,
            "my_logo": my_logo,
            "opponent_logo": opponent_logo,
            "my_pitcher": my_pitcher,
            "opponent_pitcher": opponent_pitcher
        }

        # 점수 여부에 따라 분기 처리
        away_score_tag = game.select_one('.team.away .score')
        home_score_tag = game.select_one('.team.home .score')

        if away_score_tag and home_score_tag:
            try:
                away_score = int(away_score_tag.text.strip())
                home_score = int(home_score_tag.text.strip())
                my_score = away_score if is_away else home_score
                opponent_score = home_score if is_away else away_score
                result.update({
                    "my_score": my_score,
                    "opponent_score": opponent_score,
                    "status": (
                        "WIN" if my_score > opponent_score
                        else "LOSE" if my_score < opponent_score
                        else "DRAW"
                    )
                })
            except Exception as e:
                result["status"] = "점수 파싱 오류"
                result["error"] = str(e)
        else:
            # ✅ 점수 태그가 없으면 staus에서 경기 상태 추출 (예: "경기예정", "취소", 등)
            status_tag = game.select_one('.staus')  # KBO에서 'staus'로 오타된 class
            result["status"] = status_tag.text.strip() if status_tag else "경기 정보 없음"

        return result  # ✅ 무조건 반환

    # 조건에 맞는 게임이 없을 경우
    return {"error": f"{my_team}의 경기를 찾을 수 없습니다."}

# FastAPI 라우터
@app.get("/score")
async def get_score(team: str = "doosan"):
    try:
        html = await fetch_kbo_score_html()
        html_team_name = TEAM_CODE_MAP.get(team.lower(), team)
        return parse_kbo_score_from_html(html, my_team=html_team_name)
    except Exception as e:
        return {"error": str(e)}
