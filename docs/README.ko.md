# zsh-ai

> 터미널에서 동작하는 가벼운 AI 어시스턴트

자연어를 쉘 명령어로 즉시 변환합니다. 클라우드 AI(Anthropic Claude, Google Gemini, OpenAI)와 로컬 모델(Ollama)을 모두 지원합니다. 복잡한 설정 없이 원하는 것을 입력하면 필요한 명령어를 얻을 수 있습니다.

<img src="https://img.shields.io/github/v/release/matheusml/zsh-ai?label=version&color=yellow" alt="Version"> <img src="https://img.shields.io/badge/dependencies-zero-brightgreen" alt="Zero Dependencies"> <img src="https://img.shields.io/badge/size-<5KB-blue" alt="Tiny Size"> <img src="https://img.shields.io/github/license/matheusml/zsh-ai?color=lightgrey" alt="License">

## 왜 zsh-ai인가?

**초경량** - 단일 5KB 쉘 스크립트. Python, Node.js 등 불필요.

**빠른 속도** - 쉘과 함께 즉시 시작.

**간단한 사용법** - `# 하고 싶은 것`을 입력하고 Enter. 그게 전부입니다.

**프라이버시 우선** - 로컬 Ollama 모델로 완전한 프라이버시 보장, 또는 자신의 API 키 사용. 명령어는 로컬에 유지되고, API 호출은 트리거할 때만 발생.

**제로 의존성** - 선택적으로 `jq`를 사용하면 더 안정적.

**컨텍스트 인식** - 프로젝트 타입, git 상태, 현재 디렉토리를 자동으로 감지하여 더 스마트한 제안.

## 데모

### 방법 1: 주석 문법 (권장)
`#` 뒤에 하고 싶은 것을 입력하고 Enter를 누르세요. 정말 간단합니다!

<img src="https://github.com/user-attachments/assets/eff46629-855c-41eb-9de3-a53040bd2654" alt="Method 1 Demo" width="480">


```bash
$ # 이번 주에 수정된 큰 파일 찾기
$ find . -type f -size +50M -mtime -7

$ # 포트 3000을 사용하는 프로세스 종료
$ lsof -ti:3000 | xargs kill -9

$ # 현재 디렉토리의 이미지 압축
$ for img in *.{jpg,png}; do convert "$img" -quality 85 "$img"; done
```

---

### 방법 2: 직접 명령어
명시적인 명령어를 선호하시나요? `zsh-ai` 뒤에 자연어 요청을 사용하세요.

<img src="https://github.com/user-attachments/assets/e58f0b99-68bf-45a5-87b9-ba7f925ddc87" alt="Method 2 Demo" width="480">


```bash
$ zsh-ai "이번 주에 수정된 큰 파일 찾기"
$ find . -type f -size +50M -mtime -7

$ zsh-ai "포트 3000을 사용하는 프로세스 종료"
$ lsof -ti:3000 | xargs kill -9

$ zsh-ai "현재 디렉토리의 이미지 압축"
$ for img in *.{jpg,png}; do convert "$img" -quality 85 "$img"; done
```

---

### 명령어 설명 (--e 플래그)
쿼리 끝에 `--e`를 추가하면 생성된 명령어와 함께 인라인 설명 주석을 받을 수 있습니다.

```bash
$ # 큰 파일 찾기 --e
$ find . -type f -size +100M  # 현재 디렉토리에서 100MB보다 큰 파일을 재귀적으로 찾습니다

$ zsh-ai "실행 중인 도커 컨테이너 목록" --e
$ docker ps  # 실행 중인 모든 Docker 컨테이너를 상세 정보와 함께 표시합니다
```

이 기능은 명령어가 무엇을 하는지 설명하기 위해 두 번째 API 호출을 수행합니다 - 학습이나 스크립트 문서화에 유용합니다. 설명은 실행 시 무시되는 인라인 주석으로 표시됩니다.

## 빠른 시작

### 1. 설치 (Oh My Zsh)

```bash
git clone https://github.com/matheusml/zsh-ai ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai
```

`~/.zshrc`에 추가:
```bash
plugins=(
    # 다른 플러그인들...
    zsh-ai
)
```

### 2. 설정

```bash
# 예제 설정 복사
cp ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai/.env.example \
   ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai/.env

# .env 파일을 편집하여 설정
# ZSH_AI_PROVIDER="openai"
# OPENAI_API_KEY="your-api-key"
```

### 3. 리로드 & 사용

```bash
source ~/.zshrc
```

`# 원하는 명령어`를 입력하고 Enter를 누르세요!

**[전체 설치 가이드](INSTALL.ko.md)**


## 설정

### 커스텀 접두사

`#`이 마음에 들지 않으시나요? `.env` 파일에서 변경하세요:

```bash
# "? "를 접두사로 사용
ZSH_AI_PREFIX="? "
# 이제 입력: ? 모든 파이썬 파일 찾기

# "ai "를 접두사로 사용
ZSH_AI_PREFIX="ai "
# 이제 입력: ai 모든 파이썬 파일 찾기

# ">> "를 접두사로 사용
ZSH_AI_PREFIX=">> "
# 이제 입력: >> 모든 파이썬 파일 찾기
```

### 커스텀 프롬프트

플러그인 디렉토리의 `prompt.yaml`을 편집하여 AI 동작을 커스터마이즈하세요:

```yaml
system_prompt: |
  여기에 커스텀 프롬프트...

prompt_extend: |
  추가 지시사항...
```

### 설명 언어 설정

`.env` 파일에서 `--e` 플래그 사용 시 설명 언어를 설정할 수 있습니다:

```bash
# 한국어 설명
ZSH_AI_LANG="KO"

# 영어 설명 (기본값)
ZSH_AI_LANG="EN"

# 일본어 설명
ZSH_AI_LANG="JA"
```

**[전체 설정 가이드](INSTALL.ko.md#설정-옵션)**


## 문서

- **[설치 및 설정](INSTALL.ko.md)** - 상세 설치 가이드
- **[설정](INSTALL.ko.md#설정-옵션)** - API 키, 프로바이더, 커스터마이징 옵션
- **[기여하기](../CONTRIBUTING.md)** - zsh-ai를 더 좋게 만들어주세요!
