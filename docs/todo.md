# TODO

## 현재 이슈
코드 리뷰 결과 보안, 코드 품질, 사용성 개선이 필요함

## Plan

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
- [x] Phase 1: Critical Security Fixes (P0) ✅ **완료**
  - [x] P0-1: API 키 프로세스 노출 방지
    - anthropic.zsh: 임시 헤더 파일 사용
    - openai.zsh: 임시 헤더 파일 사용
    - gemini.zsh: 주석 추가 (API 설계상 URL 파라미터 필수)
  - [x] P0-2: .env 파일 권한 검증
    - config.zsh: Linux/macOS 호환 권한 체크 추가
  - [x] P0-3: 임시 파일 권한 명시
    - widget.zsh: chmod 600 명시적 추가
- [ ] Phase 2: Code Quality Improvements (P1)
  - [ ] P1-1: JSON 파싱 로직 통합
  - [ ] P1-2: 설정값 커스터마이징
  - [ ] P1-3: 에러 메시지 표준화
- [ ] Phase 3: Documentation Cleanup
  - [ ] temp.md -> docs/ROADMAP.md 이관

## 메모
- 각 Phase는 독립적인 커밋으로 관리
- ✅ Phase 1 완료 - 보안 취약점 모두 해결
- 수정된 파일 (5개):
  - lib/providers/anthropic.zsh
  - lib/providers/openai.zsh
  - lib/providers/gemini.zsh
  - lib/config.zsh
  - lib/widget.zsh
- Phase 1 커밋 후 Phase 2 진행 예정
- 모든 변경사항은 기존 기능 유지하며 개선만 수행
- 테스트: 각 provider별 수동 테스트 필요

## 예상 소요 시간
- Phase 1: 2-3시간
- Phase 2: 3-4시간
- Phase 3: 30분
- 총: 약 6-8시간
