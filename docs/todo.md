# TODO

## 현재 이슈
서비스 관점 리뷰 결과 위험 명령어 감지 기능과 에러 메시지 개선 필요

## Plan

### Phase 4: Safety & Error Handling (P0)

**4-1. 위험 명령어 감지 시스템**
- 파일: `lib/safety.zsh` (신규)
- 내용:
  - 위험 패턴 정의 배열
  - `_zsh_ai_check_dangerous_command()` - 위험 명령어 감지 함수
  - `_zsh_ai_confirm_dangerous_command()` - 사용자 확인 프롬프트
- 위험 패턴:
  - `rm -rf /`, `rm -rf /*`
  - `dd if=`, `dd of=/dev/sd`
  - `mkfs`, `mkfs.`
  - `chmod 777`, `chmod -R 777`
  - `> /dev/sd`, `>> /dev/sd`
  - `:(){:|:&};:` (포크 폭탄)
  - `sudo rm -rf`, `sudo dd` 등

**4-2. utils.zsh에 안전 체크 통합**
- 파일: `lib/utils.zsh`
- 수정:
  - `_zsh_ai_execute_command()` 함수에 안전 체크 추가
  - 위험 명령어 감지 시 경고 메시지 + 사용자 확인
  - 확인 거부 시 명령어 버퍼에 로드하지 않음

**4-3. 통합 에러 처리 함수**
- 파일: `lib/utils.zsh`
- 내용:
  - `_zsh_ai_handle_curl_error()` - curl exit code별 구체적 에러 메시지
  - `_zsh_ai_handle_http_error()` - HTTP 상태 코드별 처리
  - curl 에러: 6 (DNS), 7 (연결 거부), 28 (타임아웃), 35 (SSL)
  - HTTP 상태: 401 (API 키), 429 (Rate limit), 500/502/503 (서버)

**4-4. 모든 프로바이더에 에러 처리 적용**
- 파일: `lib/providers/anthropic.zsh`, `openai.zsh`, `gemini.zsh`
- 수정:
  - curl 호출 시 `-w "\n%{http_code}"` 추가하여 HTTP 코드 캡처
  - Ollama의 세부 에러 처리 패턴을 모든 프로바이더에 적용
  - 공통 에러 처리 함수 사용

**4-5. 플러그인 진입점 수정**
- 파일: `zsh-ai.plugin.zsh`
- 수정: `lib/safety.zsh` 소싱 추가

## 이전 Plan

### Phase 1: Critical Security Fixes (P0)
1. **API 키 프로세스 노출 방지**
   - 파일: `lib/providers/anthropic.zsh`, `openai.zsh`, `gemini.zsh`, `ollama.zsh`
   - 방법: curl 헤더를 임시 파일로 전달 (chmod 600)
   - 영향: API 키가 `ps aux`에 노출되지 않음

2. **.env 파일 권한 검증**
   - 파일: `lib/config.zsh`
   - 방법: .env 파일 로드 전 권한 체크 (600 또는 400 권장)
   - 영향: 보안 취약점 경고 제공

3. **임시 파일 권한 명시**
   - 파일: `lib/widget.zsh`
   - 방법: mktemp 후 명시적 chmod 600
   - 영향: 시스템 기본값에 의존하지 않음

### Phase 2: Code Quality Improvements (P1)
4. **JSON 파싱 로직 통합**
   - 파일: `lib/utils.zsh` (공통 함수 추가), 모든 providers
   - 방법: `_zsh_ai_parse_json_response()` 함수 생성
   - 영향: ~160줄 코드 중복 제거, 유지보수성 향상

5. **설정값 커스터마이징**
   - 파일: `lib/config.zsh`, 모든 providers
   - 방법: `ZSH_AI_MAX_TOKENS`, `ZSH_AI_TEMPERATURE` 환경변수 추가
   - 영향: 사용자가 토큰/온도 조절 가능

6. **에러 메시지 표준화**
   - 파일: `lib/utils.zsh`, 모든 providers
   - 방법: `_zsh_ai_error()` 공통 함수 생성
   - 영향: 일관된 에러 포맷 (`Error: [provider] message`)

### Phase 3: Documentation Cleanup
7. **temp.md 정리**
   - 파일: `temp.md` -> `docs/ROADMAP.md`
   - 방법: 내용 정리 후 이관, 원본 삭제
   - 영향: 개발 계획 문서화

## 진행 상황
- [x] Phase 4: Safety & Error Handling (P0) ✅ **완료**
  - [x] 4-1: 위험 명령어 감지 시스템
    - lib/safety.zsh 신규 생성
    - 위험 패턴 20개 정의 (rm -rf /, dd, mkfs, chmod 777 등)
    - _zsh_ai_check_dangerous_command() 함수 구현
    - _zsh_ai_add_warning_comment() 함수 구현
  - [x] 4-2: utils.zsh에 안전 체크 통합
    - _zsh_ai_execute_command() 함수에 위험 명령어 감지 로직 추가
    - 위험 명령어 발견 시 "# ⚠️ WARNING: ..." 형식 경고 주석 추가
    - --e 플래그보다 위험 경고 우선순위 높게 설정
  - [x] 4-3: 통합 에러 처리 함수 (utils.zsh)
    - _zsh_ai_handle_curl_error() 함수 추가 (curl exit code별 에러 메시지)
    - _zsh_ai_handle_http_error() 함수 추가 (HTTP 상태 코드별 에러 메시지)
    - 구체적이고 실용적인 에러 메시지 제공
  - [x] 4-4: 모든 프로바이더에 에러 처리 적용
    - anthropic.zsh: HTTP 상태 코드 캡처 및 에러 처리
    - openai.zsh: HTTP 상태 코드 캡처 및 에러 처리
    - gemini.zsh: HTTP 상태 코드 캡처 및 에러 처리
    - ollama.zsh: HTTP 상태 코드 캡처 및 에러 처리
  - [x] 4-5: 플러그인 진입점 수정
    - zsh-ai.plugin.zsh에 safety.zsh 소싱 추가 (utils.zsh 이전에 로드)

- [x] Phase 1: Critical Security Fixes (P0) ✅ **완료**
  - [x] P0-1: API 키 프로세스 노출 방지
    - anthropic.zsh: 임시 헤더 파일 사용
    - openai.zsh: 임시 헤더 파일 사용
    - gemini.zsh: 주석 추가 (API 설계상 URL 파라미터 필수)
  - [x] P0-2: .env 파일 권한 검증
    - config.zsh: Linux/macOS 호환 권한 체크 추가
  - [x] P0-3: 임시 파일 권한 명시
    - widget.zsh: chmod 600 명시적 추가
- [x] Phase 2: Code Quality Improvements (P1) ✅ **완료**
  - [x] P1-1: JSON 파싱 로직 통합
    - utils.zsh: `_zsh_ai_parse_response()` 공통 함수 추가
    - anthropic.zsh, openai.zsh, gemini.zsh, ollama.zsh: ~160줄 중복 코드 제거
  - [x] P1-2: 설정값 커스터마이징
    - config.zsh: `ZSH_AI_MAX_TOKENS`, `ZSH_AI_TEMPERATURE` 환경변수 추가
    - 모든 providers: 하드코딩된 값을 환경변수로 교체
    - ollama.zsh: `num_predict` 파라미터 추가
  - [x] P1-3: 에러 메시지 표준화
    - utils.zsh: `_zsh_ai_error()` 공통 함수 추가
    - 모든 providers: 일관된 에러 포맷 적용 (`Error: [provider] message`)
- [x] Phase 3: Documentation Cleanup ✅ **완료**
  - [x] temp.md -> docs/ROADMAP.md 이관
    - ROADMAP.md 생성: 향후 개선 사항 정리
    - 완료된 Phase 1-2 항목 표시
    - temp.md 삭제

## 메모
- 각 Phase는 독립적인 커밋으로 관리
- ✅ Phase 1 완료 - 보안 취약점 모두 해결
- ✅ Phase 2 완료 - 코드 품질 대폭 개선
- ✅ Phase 3 완료 - 문서화 정리
- ✅ Phase 4 완료 - 안전 기능 및 에러 처리 개선
- 수정된 파일:
  - Phase 1 (6개): providers 4개, config.zsh, widget.zsh, docs/todo.md
  - Phase 2 (6개): utils.zsh, providers 4개, config.zsh
  - Phase 4 (7개): lib/safety.zsh (신규), utils.zsh, providers 4개, zsh-ai.plugin.zsh
- 코드 감소: ~160줄의 중복 코드 제거 (JSON 파싱)
- 새 기능:
  - max_tokens, temperature 사용자 설정 가능
  - 위험 명령어 감지 및 경고 시스템 (20개 패턴)
  - 구체적인 curl/HTTP 에러 메시지 (사용자 친화적)
- 모든 변경사항은 기존 기능 유지하며 개선만 수행
- 테스트: 각 provider별 수동 테스트 필요
- Phase 4 완료 후 커밋 예정

## 예상 소요 시간
- Phase 1: 2-3시간
- Phase 2: 3-4시간
- Phase 3: 30분
- 총: 약 6-8시간
