# zsh-ai-helper

<div align="center">

![zsh-ai-logo](https://via.placeholder.com/150?text=zsh-ai)

**자연어를 쉘 명령어로 즉시 변환하는 AI 기반 ZSH 플러그인**<br/>
강화된 안전 기능과 에러 처리를 갖춘 스마트 커맨드라인 어시스턴트

[![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![ZSH](https://img.shields.io/badge/Shell-ZSH%205.0+-blue?style=flat-square)](https://www.zsh.org/)
[![Dependencies](https://img.shields.io/badge/Dependencies-zero-brightgreen?style=flat-square)](#)
[![Size](https://img.shields.io/badge/Size-~5KB-orange?style=flat-square)](#)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS-lightgrey?style=flat-square)](#)

[English](README.md) • [문서 보기](docs/)

</div>

---

> **💡 이 프로젝트는**<br/>
> [matheusml/zsh-ai](https://github.com/matheusml/zsh-ai)를 기반으로 개발되었으며, 위험 명령어 감지, 개선된 에러 처리, 한국어 지원 등의 기능이 추가되었습니다.

---

## 📖 프로젝트 소개

**zsh-ai-helper**는 AI 기술을 활용하여 자연어를 ZSH 셸 명령어로 변환해주는 경량 플러그인입니다.

### 💡 왜 이 프로젝트가 필요한가요?

- **문제:** 복잡한 셸 명령어 문법을 외우기 어렵고, 매번 검색하는 것은 비효율적입니다.
- **해결:** 평범한 말로 원하는 작업을 설명하면, AI가 즉시 실행 가능한 명령어로 변환해줍니다.

---

## 📸 사용 예시

### 기본 사용법

```bash
$ # 최근 7일간 수정된 모든 Python 파일 찾기
$ find . -name "*.py" -mtime -7

$ # 현재 디렉토리에서 가장 큰 파일 5개 찾기
$ du -h . | sort -rh | head -5

$ # 포트 3000을 사용하는 프로세스 종료
$ lsof -ti:3000 | xargs kill -9
```

### 명령어 설명 기능 (`--e` 플래그)

```bash
$ # 큰 파일 찾기 --e
$ find . -type f -size +100M  # 현재 디렉토리에서 100MB 이상의 파일을 재귀적으로 검색합니다

$ # Docker 컨테이너 목록 보기 --e
$ docker ps -a  # 실행 중이거나 중지된 모든 Docker 컨테이너를 상세 정보와 함께 표시합니다
```

### 위험 명령어 자동 감지

```bash
$ # 모든 파일 삭제
$ rm -rf /  # ⚠️  WARNING: 시스템의 모든 파일을 삭제할 수 있습니다

$ # 전체 디스크 포맷
$ mkfs.ext4 /dev/sda  # ⚠️  WARNING: 디스크를 포맷하면 모든 데이터가 영구적으로 삭제됩니다
```

---

## ✨ 주요 기능

### 🚀 핵심 기능

| 기능 | 설명 |
|:---|:---|
| **제로 의존성** | 순수 ZSH 스크립트 (~5KB), `curl`만 필요 |
| **다중 AI 프로바이더** | Anthropic Claude, OpenAI GPT, Google Gemini, Ollama (로컬) 지원 |
| **컨텍스트 인식** | 프로젝트 타입, Git 상태, 현재 디렉토리 자동 감지 |
| **명령어 설명** | `--e` 플래그로 생성된 명령어에 대한 한국어 설명 제공 |
| **다국어 지원** | 7개 언어 지원 (EN, KO, JA, ZH, DE, FR, ES) |
| **커스터마이징** | YAML 기반 프롬프트 설정 및 커스텀 접두사 지원 |

### 🛡️ 강화된 안전 기능 (원본 프로젝트 대비 개선사항)

<details>
<summary><strong>⚠️ 위험 명령어 자동 감지</strong></summary>

20개 이상의 위험 패턴을 자동으로 감지하고 경고합니다:

- **파일 시스템 파괴**: `rm -rf /`, `dd if=/dev/zero`, `mkfs.*`
- **권한 남용**: `chmod 777`, `chmod -R 777`
- **시스템 종료**: `:(){ :|:& };:` (fork bomb), `shutdown`, `reboot`
- **강제 명령**: `--no-preserve-root`, `-f` 플래그 조합

위험한 명령어가 감지되면 자동으로 경고 주석이 추가됩니다.

</details>

<details>
<summary><strong>🔍 개선된 에러 메시지</strong></summary>

사용자 친화적인 상세 에러 안내:

**cURL 에러 처리**
- DNS 해결 실패 (에러 6): 인터넷 연결 확인 안내
- 연결 거부 (에러 7): API 서버 상태 확인 안내
- 타임아웃 (에러 28): 타임아웃 시간 조정 방법 제시
- SSL/TLS 오류 (에러 35): 인증서 문제 해결 방법 안내

**HTTP 상태 코드별 안내**
- 401 Unauthorized: API 키 확인 방법
- 429 Too Many Requests: 속도 제한 안내 및 대기 권장
- 500 Internal Server Error: 서버 문제 안내 및 재시도 권장

</details>

<details>
<summary><strong>🔒 보안 강화</strong></summary>

- **API 키 보호**: 프로세스 목록에 API 키 노출 방지
- **파일 권한 검증**: `.env` 파일 권한 자동 검사 (600 이하 권장)
- **임시 파일 보안**: API 응답 임시 파일 권한 보호 (600)

</details>

### 📝 완전한 한국어 지원

- 한국어 README 및 설치 가이드
- 한국어 명령어 설명 (`ZSH_AI_LANG="KO"`)
- 한국어 에러 메시지 (향후 지원 예정)

---

## 🚀 설치 방법

### 사전 요구사항

```bash
# ZSH 버전 확인
zsh --version  # 5.0 이상 필요

# curl 설치 확인
which curl

# jq 설치 (선택사항, 더 안정적인 JSON 파싱)
# Ubuntu/Debian
sudo apt install jq
# macOS
brew install jq
```

### Oh My Zsh 사용자 (권장)

```bash
# 1. 플러그인 디렉토리에 클론
git clone https://github.com/Bae-ChangHyun/zsh-ai-helper ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai-helper

# 2. ~/.zshrc 파일 편집
# plugins 배열에 zsh-ai-helper 추가
plugins=(... zsh-ai-helper)

# 3. 설정 파일 생성
cp ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai-helper/.env.example \
   ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai-helper/.env

# 4. .env 파일에서 API 키 설정 (에디터로 열기)
nano ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai-helper/.env

# 5. ZSH 재시작
source ~/.zshrc
```

<details>
<summary><strong>수동 설치 방법</strong></summary>

Oh My Zsh를 사용하지 않는 경우:

```bash
# 1. 원하는 위치에 클론
git clone https://github.com/Bae-ChangHyun/zsh-ai-helper ~/.zsh-ai-helper

# 2. ~/.zshrc에 다음 라인 추가
source ~/.zsh-ai-helper/zsh-ai.plugin.zsh

# 3. 설정 파일 생성 및 편집
cp ~/.zsh-ai-helper/.env.example ~/.zsh-ai-helper/.env
nano ~/.zsh-ai-helper/.env

# 4. ZSH 재시작
source ~/.zshrc
```

</details>

---

## 📖 사용 가이드

### 방법 1: 주석 문법 (권장)

`#` 기호 뒤에 자연어로 원하는 작업을 설명하고 Enter를 누르세요:

```bash
$ # 최근 24시간 내 수정된 로그 파일 찾기
$ find /var/log -name "*.log" -mtime -1

$ # CPU 사용률 상위 10개 프로세스 표시
$ ps aux --sort=-%cpu | head -11

$ # Git에서 마지막 커밋 취소하기
$ git reset --soft HEAD~1
```

### 방법 2: 직접 명령어

`zsh-ai` 명령어를 직접 사용:

```bash
$ zsh-ai "Docker 이미지 전체 삭제"
$ docker rmi $(docker images -q)

$ zsh-ai "현재 디렉토리의 모든 .txt 파일을 .md로 변환"
$ for file in *.txt; do mv "$file" "${file%.txt}.md"; done
```

### 방법 3: 명령어 설명 받기

`--e` 플래그를 추가하면 생성된 명령어에 대한 설명을 주석으로 받을 수 있습니다:

```bash
$ # 네트워크 사용량 실시간 모니터링 --e
$ nethogs  # 프로세스별 네트워크 대역폭 사용량을 실시간으로 표시합니다

$ zsh-ai "시스템 메모리 사용량 확인" --e
$ free -h  # 시스템의 메모리 사용 현황을 사람이 읽기 쉬운 형태로 표시합니다
```

---

## ⚙️ 설정 가이드

### AI 프로바이더 설정

`.env` 파일에서 사용할 AI 프로바이더와 API 키를 설정합니다:

#### 지원 프로바이더

| 프로바이더 | API 키 변수명 | 기본 모델 | 비용 | 특징 |
|:---:|:---:|:---:|:---:|:---|
| **Anthropic** | `ANTHROPIC_API_KEY` | `claude-haiku-4.5` | 💰 유료 | 빠르고 정확, 권장 |
| **OpenAI** | `OPENAI_API_KEY` | `gpt-4o` | 💰 유료 | 범용성 우수 |
| **Gemini** | `GEMINI_API_KEY` | `gemini-2.5-flash` | 💰 유료 | Google의 최신 모델 |
| **Ollama** | (없음) | `llama3.2` | 🆓 무료 | 로컬 실행, 인터넷 불필요 |

#### API 키 발급 방법

<details>
<summary><strong>Anthropic Claude (권장)</strong></summary>

1. [Anthropic Console](https://console.anthropic.com/) 접속
2. API Keys 메뉴에서 새 키 생성
3. `.env` 파일에 설정:

```bash
ZSH_AI_PROVIDER=anthropic
ANTHROPIC_API_KEY=sk-ant-api03-xxxxx
ANTHROPIC_MODEL=claude-haiku-4.5  # 또는 claude-sonnet-4.5
```

</details>

<details>
<summary><strong>OpenAI GPT</strong></summary>

1. [OpenAI Platform](https://platform.openai.com/api-keys) 접속
2. "Create new secret key" 클릭
3. `.env` 파일에 설정:

```bash
ZSH_AI_PROVIDER=openai
OPENAI_API_KEY=sk-proj-xxxxx
OPENAI_MODEL=gpt-4o  # 또는 gpt-4o-mini
```

</details>

<details>
<summary><strong>Google Gemini</strong></summary>

1. [Google AI Studio](https://makersuite.google.com/app/apikey) 접속
2. API 키 생성
3. `.env` 파일에 설정:

```bash
ZSH_AI_PROVIDER=gemini
GEMINI_API_KEY=AIzaSyxxxxx
GEMINI_MODEL=gemini-2.5-flash
```

</details>

<details>
<summary><strong>Ollama (로컬, 무료)</strong></summary>

1. [Ollama](https://ollama.ai/) 설치
2. 모델 다운로드:

```bash
ollama pull llama3.2
# 또는 다른 모델
ollama pull codellama
```

3. `.env` 파일에 설정:

```bash
ZSH_AI_PROVIDER=ollama
OLLAMA_MODEL=llama3.2
OLLAMA_BASE_URL=http://localhost:11434  # 기본값
```

</details>

### 고급 설정 옵션

#### 트리거 접두사 변경 (`ZSH_AI_PREFIX`)

기본 `#` 대신 다른 접두사 사용:

```bash
# .env 파일
ZSH_AI_PREFIX="? "    # 사용: ? 파이썬 파일 찾기
ZSH_AI_PREFIX="ai "   # 사용: ai 파이썬 파일 찾기
ZSH_AI_PREFIX=">> "   # 사용: >> 시스템 업데이트
```

#### 설명 언어 변경 (`ZSH_AI_LANG`)

`--e` 플래그 사용 시 설명 언어 설정:

```bash
# .env 파일
ZSH_AI_LANG="KO"   # 한국어 (기본값: EN)
ZSH_AI_LANG="JA"   # 일본어
ZSH_AI_LANG="ZH"   # 중국어
```

#### 타임아웃 설정 (`ZSH_AI_TIMEOUT`)

API 요청 타임아웃 시간 (초):

```bash
# .env 파일
ZSH_AI_TIMEOUT=60   # 느린 네트워크 환경
ZSH_AI_TIMEOUT=15   # 빠른 응답이 필요한 경우
```

#### LLM 파라미터 조정 (`ZSH_AI_EXTRA_KWARGS`)

모델의 창의성, 무작위성 등을 제어:

```bash
# .env 파일
# 더 결정론적인 응답 (낮은 temperature)
ZSH_AI_EXTRA_KWARGS='{"temperature": 0.1}'

# 더 창의적인 응답 (높은 temperature)
ZSH_AI_EXTRA_KWARGS='{"temperature": 0.9, "top_p": 0.95}'
```

### 커스텀 프롬프트 설정

`prompt.yaml` 파일을 편집하여 AI의 동작 방식을 세밀하게 조정:

```yaml
system_prompt: |
  당신은 ZSH 명령어 생성 전문가입니다.
  사용자의 자연어 요청을 정확한 ZSH 명령어로 변환하세요.

prompt_extend: |
  - 명령어는 반드시 실행 가능해야 합니다
  - 위험한 명령어는 경고 주석을 포함하세요
  - 효율적이고 간결한 명령어를 우선하세요

explain_prompt: |
  생성된 명령어를 {lang} 언어로 간단히 설명하세요.
  설명은 한 문장으로 작성하고, 기술적 세부사항보다는
  명령어가 '무엇을 하는지'에 집중하세요.
```

---

## 💻 기술 스택

<div align="center">

![ZSH](https://img.shields.io/badge/Shell-ZSH-89e051?style=for-the-badge&logo=zsh&logoColor=white)
![cURL](https://img.shields.io/badge/HTTP-cURL-073551?style=for-the-badge&logo=curl&logoColor=white)
![Anthropic](https://img.shields.io/badge/AI-Anthropic%20Claude-181818?style=for-the-badge)
![OpenAI](https://img.shields.io/badge/AI-OpenAI%20GPT-412991?style=for-the-badge&logo=openai&logoColor=white)
![Gemini](https://img.shields.io/badge/AI-Google%20Gemini-4285F4?style=for-the-badge&logo=google&logoColor=white)

</div>

### 프로젝트 구조

```
zsh-ai-helper/
├── zsh-ai.plugin.zsh       # 플러그인 진입점
├── .env.example            # 설정 템플릿
├── prompt.yaml             # AI 프롬프트 설정
├── lib/
│   ├── config.zsh          # 설정 및 .env 로딩
│   ├── context.zsh         # 컨텍스트 감지 (git, 프로젝트 타입, OS)
│   ├── utils.zsh           # 공통 유틸리티 및 메인 함수
│   ├── widget.zsh          # ZLE 위젯 (# 문법)
│   └── providers/
│       ├── anthropic.zsh   # Anthropic Claude API
│       ├── openai.zsh      # OpenAI GPT API
│       ├── gemini.zsh      # Google Gemini API
│       └── ollama.zsh      # Ollama 로컬 API
└── docs/
    ├── README.ko.md        # 한국어 문서
    └── ROADMAP.md          # 프로젝트 로드맵
```

---

## 📊 원본 프로젝트와 비교

| 기능 | 원본 (zsh-ai) | 이 프로젝트 (zsh-ai-helper) |
|:---:|:---:|:---:|
| **기본 기능** | ✅ | ✅ |
| **다중 AI 프로바이더** | ✅ | ✅ |
| **명령어 설명** | ✅ | ✅ |
| **위험 명령어 감지** | ❌ | ✅ **20개 이상 패턴** |
| **상세 에러 메시지** | ❌ | ✅ **cURL/HTTP 에러별 안내** |
| **API 키 보안** | ⚠️ 부분적 | ✅ **프로세스 노출 방지** |
| **파일 권한 검증** | ❌ | ✅ **.env 권한 자동 검사** |
| **한국어 문서** | ❌ | ✅ **완전한 한국어 지원** |

---

## 🤝 기여하기

프로젝트 개선에 기여하고 싶으시다면:

1. 이 저장소를 Fork
2. 새 브랜치 생성 (`git checkout -b feature/amazing-feature`)
3. 변경사항 커밋 (`git commit -m 'feat: add amazing feature'`)
4. 브랜치에 Push (`git push origin feature/amazing-feature`)
5. Pull Request 생성

자세한 내용은 [CONTRIBUTING.md](CONTRIBUTING.md)를 참조하세요.

---

## 📄 라이선스

MIT License로 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

**Copyright (c) 2024**
- 원본 프로젝트: [zsh-ai](https://github.com/matheusml/zsh-ai) by Matheus Lao
- Fork 및 개선: Bae Chang Hyun

---

## 🙏 감사의 말

이 프로젝트는 [matheusml/zsh-ai](https://github.com/matheusml/zsh-ai)를 기반으로 개발되었습니다. 훌륭한 오픈소스 프로젝트를 공유해주신 원작자와 기여자 여러분께 감사드립니다.

### 주요 개선 사항

- 위험 명령어 자동 감지 시스템
- 사용자 친화적인 에러 메시지
- 강화된 보안 (API 키 보호, 파일 권한 검증)
- 완전한 한국어 문서화

---

<div align="center">

**문의 및 이슈 리포트**<br/>
[GitHub Issues](https://github.com/Bae-ChangHyun/zsh-ai-helper/issues)

Made with ❤️ by [Bae Chang Hyun](https://github.com/Bae-ChangHyun)<br/>
Based on [zsh-ai](https://github.com/matheusml/zsh-ai)

</div>
