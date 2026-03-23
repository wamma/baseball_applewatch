# 개발 환경 세팅 세션 (2026-03-20)

## 목표
MacBook Air에서 baseball_applewatch 프로젝트 개발 환경 세팅

---

## 1. 필수 패키지 설치

### Makefile에서 파악한 필요 패키지
| 패키지 | 용도 |
|--------|------|
| Docker Desktop | `docker-compose up` |
| cloudflared | Cloudflare 터널 (백엔드 외부 노출) |
| Flutter | Flutter SDK |
| Ruby 3.4 + CocoaPods | iOS pod install |

### 설치 결과
```sh
# cloudflared
brew install cloudflared   # 2026.3.0 설치 완료

# Flutter (이미 설치되어 있었음)
brew install --cask flutter  # 3.41.5

# Ruby 3.4
brew install ruby@3.4  # 3.4.9 설치 완료

# CocoaPods (Ruby 3.4의 user gem으로 설치)
/opt/homebrew/opt/ruby@3.4/bin/gem install --user-install cocoapods  # 1.16.2
# 설치 경로: ~/.local/share/gem/ruby/3.4.0/bin/pod  ← Makefile 경로와 일치
```

### Docker Desktop
`/usr/local/cli-plugins` 디렉토리가 없어 sudo 필요. 터미널에서 직접 실행:
```sh
sudo mkdir -p /usr/local/cli-plugins
brew install --cask docker
```

---

## 2. PATH 설정 (`~/.zshrc`)

```sh
export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/homebrew/opt/make/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/opt/ruby@3.4/bin:$HOME/.local/share/gem/ruby/3.4.0/bin:$PATH"
```

---

## 3. 문제 해결

### 문제 1: cloudflared URL 추출 실패
**원인**: `Makefile`의 `sleep 5`가 너무 짧아 터널이 뜨기 전에 URL을 읽으려 함
**해결**: `sleep 5` → `sleep 10` 으로 수정 (`Makefile` line 42)

### 문제 2: `Runner.xcodeproj` 없음 (치명적)
**원인**: `*.xcodeproj` 패턴이 gitignore에서 무시되어 git에 커밋된 적 없음
**해결**:
```sh
# flutter create로 재생성
flutter create . --platforms=ios

# force-add (gitignore 우회)
git add --force \
  ios/Runner.xcodeproj/project.pbxproj \
  ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme \
  ios/Runner.xcworkspace/contents.xcworkspacedata \
  ios/Runner.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings \
  ios/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist

# ios/.gitignore에 예외 규칙 추가 (아래 섹션 참고)
```

---

## 4. 맥북 ↔ 맥미니 Xcode 설정 일관성 유지

### `ios/.gitignore`에 추가한 예외 규칙
```gitignore
# Xcode project files must be tracked for cross-machine consistency
!Runner.xcodeproj/
!Runner.xcodeproj/project.pbxproj
!Runner.xcodeproj/xcshareddata/
!Runner.xcodeproj/xcshareddata/xcschemes/
!Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme
!Runner.xcworkspace/
!Runner.xcworkspace/contents.xcworkspacedata
!Runner.xcworkspace/xcshareddata/
!Runner.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings
```

### 커밋해야 할 것 vs 말아야 할 것
| 파일 | 커밋 | 이유 |
|------|------|------|
| `project.pbxproj` | O | 타겟, 빌드 설정, 파일 참조 전체 포함 |
| `xcshareddata/xcschemes/` | O | 빌드/실행 스킴 공유 |
| `xcworkspace/contents.xcworkspacedata` | O | 워크스페이스 구성 |
| `xcuserdata/` | X | 브레이크포인트, 창 레이아웃 등 개인 설정 |

### 새 타겟 추가 후 워크플로우 (Widget, WatchApp 등)
```sh
# Xcode에서 타겟 추가 후
git add ios/Runner.xcodeproj/project.pbxproj
git commit -m "feat: MyTeamWidget 타겟 추가"
git push

# 다른 Mac에서
git pull
```

---

## 5. 최종 커밋 내역
```
d4c1dea fix: Runner.xcodeproj 복구 및 cross-machine Xcode 설정 일관성 확보
- flutter create로 Runner.xcodeproj, Runner.xcworkspace 재생성
- ios/.gitignore에 xcodeproj/xcworkspace 예외 규칙 추가
- Makefile cloudflared sleep 5 → 10으로 수정
```
