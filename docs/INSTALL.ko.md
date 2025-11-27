# 설치 가이드

## 사전 요구사항

- zsh 5.0+ (이미 설치되어 있을 가능성이 높습니다)
- `curl` (macOS/Linux에 기본 포함)
- `jq` (선택사항, 더 안정적인 동작을 위해)

**AI 프로바이더 선택:**
- **Anthropic Claude** (기본값): [API 키 발급](https://console.anthropic.com/account/keys)
- **Google Gemini**: [API 키 발급](https://makersuite.google.com/app/apikey)
- **OpenAI**: [API 키 발급](https://platform.openai.com/api-keys)
- **Ollama** (로컬): [Ollama 설치](https://ollama.ai/download)

## 설치

### Oh My Zsh

1. 저장소 클론
```bash
git clone https://github.com/matheusml/zsh-ai ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai
```

2. `~/.zshrc`의 플러그인 목록에 `zsh-ai` 추가:

```bash
plugins=(
    # 다른 플러그인들...
    zsh-ai
)
```

3. 새 터미널 세션 시작

```bash
source ~/.zshrc
```

## 설정

`.env` 파일을 사용하여 zsh-ai를 설정합니다:

1. 예제 파일 복사:
```bash
cp ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai/.env.example ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai/.env
```

2. `.env` 파일을 편집하여 설정합니다:

플러그인은 다음 위치에서 자동으로 `.env`를 로드합니다:
- 플러그인 디렉토리 (우선순위)
- `~/.zsh-ai.env` (대체 위치)

**참고:** 선택한 프로바이더의 API 키를 설정해야 합니다.


## 사용 옵션

### 명령어 설명 (--e 플래그)

쿼리 끝에 `--e`를 추가하면 생성된 명령어와 함께 인라인 설명 주석을 받을 수 있습니다:

```bash
# 주석 문법 사용
$ # 큰 파일 찾기 --e
$ find . -type f -size +100M  # 100MB보다 큰 파일을 재귀적으로 찾습니다

# 직접 명령어 사용
$ zsh-ai "모든 이미지 압축" --e
$ for img in *.{jpg,png}; do convert "$img" -quality 85 "$img"; done  # 이미지를 85% 품질로 압축합니다
```

이 기능은 명령어를 설명하기 위해 두 번째 API 호출을 수행합니다 - 학습이나 스크립트 문서화에 유용합니다. 설명은 실행 시 무시되는 인라인 주석으로 표시됩니다.

## 설정 옵션

`.env` 파일의 모든 설정:

```bash
# 프로바이더: "anthropic" (기본값), "gemini", "openai", "ollama"
ZSH_AI_PROVIDER="openai"

# API 키 (선택한 프로바이더만 설정)
OPENAI_API_KEY="your-key"
ANTHROPIC_API_KEY="your-key"
GEMINI_API_KEY="your-key"

# 프로바이더별 모델
ZSH_AI_OPENAI_MODEL="gpt-4o"
ZSH_AI_ANTHROPIC_MODEL="claude-haiku-4-5"
ZSH_AI_GEMINI_MODEL="gemini-2.5-flash"
ZSH_AI_OLLAMA_MODEL="llama3.2"

# 커스텀 API 엔드포인트
ZSH_AI_OPENAI_URL="https://api.openai.com/v1/chat/completions"
ZSH_AI_OLLAMA_URL="http://localhost:11434"

# AI 트리거 명령어 접두사 (기본값: "# ")
# 예시: "? ", "ai ", ">> "
ZSH_AI_PREFIX="# "

# 요청 타임아웃 (초, 기본값: 30)
ZSH_AI_TIMEOUT=30

# --e 플래그 설명 언어 (기본값: "EN")
# 예시: "EN" (영어), "KO" (한국어), "JA" (일본어), "ZH" (중국어)
ZSH_AI_LANG="KO"

# LLM API 호출을 위한 추가 kwargs (JSON 형식)
ZSH_AI_EXTRA_KWARGS='{"temperature": 0.1}'
```


## 프롬프트 커스터마이징

플러그인 디렉토리의 `prompt.yaml`을 편집하여 AI 프롬프트를 커스터마이즈할 수 있습니다:

```yaml
system_prompt: |
  zsh 명령어 생성기입니다...

  여기에 커스텀 지시사항.

# 선택사항: 메인 프롬프트를 대체하지 않고 추가 지시사항 추가
prompt_extend: |
  항상 ripgrep, fd, bat 같은 최신 CLI 도구를 선호하세요.

# 선택사항: --e 플래그를 위한 커스텀 설명 프롬프트
explain_prompt: |
  쉘 명령어 설명기입니다. 주어진 쉘 명령어가 무엇을 하는지 간단히 설명하세요.

  규칙:
  1. 설명 텍스트만 출력 - 마크다운, 포맷팅 없음
  2. 간결하게 (1-2문장)
  3. 명령어가 무엇을 하는지에 집중
```


## 문제 해결

### API 키 오류
- `.env` 파일에 올바른 API 키가 설정되어 있는지 확인하세요
- 프로바이더 설정이 API 키와 일치하는지 확인하세요

### Ollama 연결 오류
- Ollama가 실행 중인지 확인: `ollama serve`
- URL이 올바른지 확인: 기본값은 `http://localhost:11434`

### 응답이 느림
- `ZSH_AI_TIMEOUT` 값을 늘려보세요
- 더 빠른 모델을 사용해보세요 (예: `claude-haiku-4-5`, `gpt-4o-mini`)
