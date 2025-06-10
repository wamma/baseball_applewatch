# 1. 베이스 이미지 선택
FROM python:3.11-slim

# 2. 작업 디렉토리 설정
WORKDIR /app

# 3. 시스템 패키지 설치 (playwright에 필수)
RUN apt-get update && apt-get install -y \
	wget curl gnupg ca-certificates fonts-liberation libnss3 libatk-bridge2.0-0 \
	libgtk-3-0 libxss1 libasound2 libxcomposite1 libxdamage1 libxrandr2 \
	libgbm1 libx11-xcb1 libxext6 libxfixes3 libxi6 libgl1-mesa-glx \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# 4. requirements.txt 복사 및 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 5. playwright 브라우저 설치
RUN playwright install --with-deps

# 6. 앱 코드 복사
COPY . .

# 7. FastAPI 서버 실행 명령
CMD ["uvicorn", "score_server:app", "--host", "0.0.0.0", "--port", "8000"]
