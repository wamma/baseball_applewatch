# KBO 데이터 소스 조사

날짜: 2026-03-19

---

## 현재 방식

- **크롤링 대상**: https://www.koreabaseball.com/Schedule/GameCenter/Main.aspx
- **방법**: Playwright로 HTML 크롤링 후 BeautifulSoup으로 파싱
- **갱신 주기**:
  - TeamStatusPage (마이팀 화면): 1분마다 자동 갱신
  - AllGamesPage (전체 경기): 수동 pull-to-refresh만
  - iOS 위젯: 5분마다 자동 갱신

---

## App Store 게시 시 리스크

### App Store 심사
- Apple은 데이터 출처 합법성을 직접 심사하지 않음
- Guideline 5.2 (지식재산권): 타인 콘텐츠 무단 사용 앱은 거절 가능

### KBO 측 리스크
- KBO 이용약관에 무단 크롤링 금지 조항 있을 가능성 높음
- 상업적 목적이면 더 민감
- KBO 측 법적 조치 또는 서버 차단 가능

### 서비스 안정성
- KBO 사이트 구조 변경 시 앱 즉시 작동 불능
- IP 차단 위험

---

## KBO 공식 API 여부

**공개 API 없음**

- KBO 사이트는 내부 비공개 웹서비스만 사용
- KBO 사이트 운영사: sports2i (marketing@sports2i.com)
- 외부 개발자용 공식 API 미제공

---

## 합법적 대안 API 조사

### TheSportsDB

- **사이트**: https://www.thesportsdb.com
- **KBO 리그 ID**: 4830
- **KBO 데이터 확인**: ✅ 있음
- **제공 데이터**:
  - 시즌 전체 경기 결과 (2012~2026)
  - 점수, 이닝별 득점, 히트/에러 수
  - 10개 구단 팀 정보
  - 다음 경기 일정, 지난 경기 결과
- **실시간 라이브 스코어**: 유료 플랜($9/월)만 가능, 2분 딜레이
- **무료 API 예시**:
  - `GET https://www.thesportsdb.com/api/v1/json/3/eventsseason.php?id=4830&s=2025`
  - `GET https://www.thesportsdb.com/api/v1/json/3/eventsnextleague.php?id=4830`
  - `GET https://www.thesportsdb.com/api/v1/json/3/eventspastleague.php?id=4830`

### API-Sports

- **사이트**: https://api-sports.io
- **KBO 데이터 확인**: ⚠️ 미확인 (Cloudflare로 자동 조회 불가)
- **무료 플랜**: 하루 100 요청
- **유료 플랜**: $10/월~
- **확인 방법**: 직접 회원가입 후 `/leagues` 엔드포인트에서 KBO 지원 여부 확인 필요

### Sportradar

- **KBO 지원**: 확인 필요 (Global Baseball v2)
- **비용**: 엔터프라이즈급 (개인 프로젝트 부적합)

---

## 비교 표

| 항목 | 현재 (크롤링) | TheSportsDB | API-Sports |
|------|-------------|-------------|------------|
| 합법성 | 회색지대 | 명확히 합법 | 명확히 합법 |
| 실시간성 | 수초 이내 | 2분 딜레이 (유료) | 미확인 |
| 비용 | 서버비만 | 무료 ~ $9/월 | 무료 ~ $10/월 |
| 안정성 | 사이트 변경 시 깨짐 | 안정적 | 안정적 |
| KBO 데이터 확인 | ✅ | ✅ | ⚠️ |

---

## 결론

- 앱스토어 게시가 목표라면 **TheSportsDB** 또는 **API-Sports**가 현실적
- 실시간 점수가 핵심이라면 유료 플랜 필요
- 개인/비상업 앱이라면 현재 크롤링 방식도 현실적으로 문제될 가능성 낮으나 법적 리스크 존재
- KBO 공식 데이터 사용을 원한다면 sports2i에 직접 계약 문의 필요
