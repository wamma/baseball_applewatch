# KBO 데이터 API 조사 결과

## 1. TheSportsDB

- **사이트**: https://www.thesportsdb.com
- **KBO 리그 ID**: 4830

### 무료 API 테스트 결과

| 엔드포인트 | 결과 |
|-----------|------|
| `eventsseason.php?id=4830&s=2025` | ✅ KBO 데이터 정상 수신 |
| `eventsnextleague.php?id=4830` | ⚠️ English League 1 반환 (KBO 시즌 전이라 fallback) |
| `eventspastleague.php?id=4830` | ⚠️ English League 1 반환 (동일 이유) |

**시즌 데이터 예시** (2025-03-08):
- NC Dinos 1 vs Kiwoom Heroes 3 (Changwon NC Park)
- Hanwha Eagles 4 vs Doosan Bears 6 (Daejeon Hanbat Baseball Stadium)
- KT Wiz 5 vs LG Twins 1 (Suwon Baseball Stadium)

포함 필드: 팀명, 날짜, 최종 스코어, 경기장, 이닝별 기록, 영상 링크 등

### 실시간 라이브 스코어

유료 플랜($9/월)의 라이브스코어 지원 종목:
> "2 min livescore (Soccer, NFL, NBA, MLB, NHL)"

**KBO가 목록에 없음** - 유료 결제 전 support@thesportsdb.com으로 KBO 지원 여부 문의 필요

### 플랜별 기능

| 기능 | 무료 | $9/월 | $20/월 |
|------|------|-------|--------|
| API 요청 | 30/분 | 100/분 | 120/분 |
| KBO 과거 데이터 | ✅ | ✅ | ✅ |
| 라이브스코어 (MLB 등) | ❌ | 2분 딜레이 | 2분 딜레이 |
| KBO 실시간 | ❌ | 불명확 | 불명확 |

---

## 2. API-Sports

- **사이트**: https://api-sports.io
- **문서**: https://api-sports.io/documentation/baseball/v1
- **KBO 지원**: ✅ **KBO**, **KBO Futures League** 명시 확인

### 지원 리그 (77개)

KBO 외 주요 리그:
- MLB (미국)
- NPB (일본)
- CPBL (대만)
- LMB (멕시코) 등

### 플랜

| 플랜 | 요청 한도 | 가격 |
|------|----------|------|
| Free | 100 요청/일 | 무료 |
| PRO | 7,500 요청/일 | $15/월 |
| ULTRA | 75,000 요청/일 | $25/월 |
| MEGA | 150,000 요청/일 | $35/월 |

모든 유료 플랜은 전체 엔드포인트 및 전체 리그 접근 가능

### 미확인 사항

- KBO 실시간 라이브 스코어 포함 여부: 회원가입 후 `/games?live=all` 엔드포인트로 직접 테스트 필요

---

## 종합 비교

| | TheSportsDB | API-Sports |
|---|---|---|
| KBO 과거 데이터 | ✅ 무료 | ✅ 무료(100req/일) |
| KBO 일정 | ✅ (시즌 중) | ✅ |
| KBO 실시간 | ❌ 불명확 | 확인 필요 |
| KBO 명시 여부 | ❌ 목록 없음 | ✅ 명시됨 |
| 최저 유료 가격 | $9/월 | $15/월 |

## 결론

- **KBO 과거/일정 데이터**: TheSportsDB 무료로 충분
- **KBO 실시간 데이터**: API-Sports가 KBO를 명시적으로 지원하므로 우선 검토 권장
- **실시간 필요 시**: API-Sports 무료 가입 후 라이브 엔드포인트 테스트 후 결정
