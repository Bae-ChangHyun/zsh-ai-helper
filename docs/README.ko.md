# zsh-ai

> 자연어를 쉘 명령어로 즉시 변환

<img src="https://img.shields.io/github/v/release/matheusml/zsh-ai?label=version&color=yellow" alt="Version"> <img src="https://img.shields.io/badge/dependencies-zero-brightgreen" alt="Zero Dependencies"> <img src="https://img.shields.io/badge/size-<5KB-blue" alt="Tiny Size"> <img src="https://img.shields.io/github/license/matheusml/zsh-ai?color=lightgrey" alt="License">

AI를 사용하여 자연어를 쉘 명령어로 변환하는 경량 ZSH 플러그인입니다. Anthropic Claude, OpenAI, Google Gemini, 로컬 Ollama 모델을 지원합니다.

## 기능

- **제로 의존성** - 순수 쉘 스크립트 (~5KB), `curl`만 필요
- **다중 프로바이더** - Anthropic, OpenAI, Gemini, Ollama (로컬)
- **컨텍스트 인식** - 프로젝트 타입, git 상태, 현재 디렉토리 감지
- **명령어 설명** - `--e` 플래그로 생성된 명령어 설명
- **다국어 지원** - EN, KO, JA, ZH, DE, FR, ES로 설명 제공
- **커스터마이징** - 커스텀 접두사, YAML을 통한 프롬프트 설정

## 설치

### 사전 요구사항

- zsh 5.0+
- `curl`
- `jq` (선택사항, 더 안정적인 동작을 위해)

### Oh My Zsh

```bash
# 1. 클론
git clone https://github.com/matheusml/zsh-ai ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai

# 2. ~/.zshrc에 추가
plugins=(... zsh-ai)

# 3. 설정
cp ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai/.env.example \
   ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai/.env

# 4. .env 파일에 프로바이더와 API 키 설정

# 5. 리로드
source ~/.zshrc
```

## 사용법

### 주석 문법 (권장)

`#` 뒤에 요청을 입력하고 Enter:

<img src="https://github.com/user-attachments/assets/eff46629-855c-41eb-9de3-a53040bd2654" alt="Method 1 Demo" width="480">

```bash
$ # 이번 주에 수정된 큰 파일 찾기
$ find . -type f -size +50M -mtime -7

$ # 포트 3000을 사용하는 프로세스 종료
$ lsof -ti:3000 | xargs kill -9
```

### 직접 명령어

`zsh-ai` 명령어 직접 사용:

<img src="https://github.com/user-attachments/assets/e58f0b99-68bf-45a5-87b9-ba7f925ddc87" alt="Method 2 Demo" width="480">

```bash
$ zsh-ai "이번 주에 수정된 큰 파일 찾기"
$ find . -type f -size +50M -mtime -7
```

### 명령어 설명 (--e)

`--e`를 추가하면 인라인 설명을 받을 수 있습니다:

```bash
$ # 큰 파일 찾기 --e
$ find . -type f -size +100M  # 100MB보다 큰 파일을 재귀적으로 찾습니다

$ zsh-ai "도커 컨테이너 목록" --e
$ docker ps  # 실행 중인 모든 Docker 컨테이너를 상세 정보와 함께 표시합니다
```

## 설정

모든 설정은 `.env` 파일에 있습니다. 사용 가능한 모든 옵션은 `.env.example`을 참조하세요.

### 프로바이더

| 프로바이더 | API 키 변수 | 기본 모델 |
|----------|-----------------|---------------|
| Anthropic | `ANTHROPIC_API_KEY` | claude-haiku-4-5 |
| OpenAI | `OPENAI_API_KEY` | gpt-4o |
| Gemini | `GEMINI_API_KEY` | gemini-2.5-flash |
| Ollama | - (로컬) | llama3.2 |

### 옵션

#### `ZSH_AI_PREFIX`
트리거 접두사 변경 (기본값: `# `):
```bash
ZSH_AI_PREFIX="? "    # 사용: ? 파이썬 파일 찾기
ZSH_AI_PREFIX="ai "   # 사용: ai 파이썬 파일 찾기
```

#### `ZSH_AI_LANG`
`--e` 플래그의 설명 언어 설정 (기본값: `EN`):
```bash
ZSH_AI_LANG="KO"   # 한국어
ZSH_AI_LANG="JA"   # 일본어
ZSH_AI_LANG="ZH"   # 중국어
```

#### `ZSH_AI_TIMEOUT`
API 요청 타임아웃 (초, 기본값: `30`):
```bash
ZSH_AI_TIMEOUT=60   # 느린 연결을 위해 증가
```

#### `ZSH_AI_EXTRA_KWARGS`
LLM 파라미터를 JSON 형식으로 오버라이드:
```bash
ZSH_AI_EXTRA_KWARGS='{"temperature": 0.1}'
ZSH_AI_EXTRA_KWARGS='{"temperature": 0.5, "top_p": 0.9}'
```

### 커스텀 프롬프트

`prompt.yaml`을 편집하여 AI 동작을 커스터마이즈:

```yaml
system_prompt: |
  커스텀 시스템 프롬프트...

prompt_extend: |
  추가 지시사항...

explain_prompt: |
  --e 플래그를 위한 커스텀 설명 프롬프트...
```

## 프로젝트 구조

```
zsh-ai/
├── zsh-ai.plugin.zsh    # 진입점
├── .env.example         # 설정 템플릿
├── prompt.yaml          # 프롬프트 설정
├── lib/
│   ├── config.zsh       # 설정 로더
│   ├── context.zsh      # 컨텍스트 감지
│   ├── utils.zsh        # 핵심 유틸리티
│   ├── widget.zsh       # ZLE 위젯
│   └── providers/
│       ├── anthropic.zsh
│       ├── openai.zsh
│       ├── gemini.zsh
│       └── ollama.zsh
└── docs/
    ├── README.ko.md     # 한국어 문서
    └── INSTALL.ko.md
```

## 문서

- [기여하기](../CONTRIBUTING.md)

### English
- [README](../README.md)

## 라이선스

MIT
