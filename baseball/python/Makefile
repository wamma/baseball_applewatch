# backend/Makefile  (Mac mini 전용)
.PHONY: up down logs restart

up:        ## 이미지 빌드 + 컨테이너 실행
	docker compose up -d --build

down:      ## 컨테이너/네트워크/볼륨 제거
	docker compose down --remove-orphans

logs:      ## 실시간 로그 보기
	docker compose logs -f

restart: down up
