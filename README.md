# specrail

AI가 **스펙이라는 레일 위에서만** 움직이게 하는 Claude Code 플러그인입니다.

- **스펙 기반 개발 (AI-DLC)**: 요구사항 → 설계 → 작업 목록 → 구현. 단계마다 사람이 승인해야 다음 단계로 넘어갑니다.
- **세션 메모리**: `/clear`나 자동 압축 뒤에도 인계 노트, 진행 로그, 스펙 진행 상태를 자동으로 다시 불러옵니다.

필요 도구: `bash`, `jq` (macOS는 기본 포함, 없으면 `brew install jq`)

## 설치

Claude Code 안에서:

```text
/plugin marketplace add 0ssang/specrail
/plugin install specrail@specrail
```

로컬에서 개발 중이라면 `0ssang/specrail` 대신 이 폴더 경로(예: `/Users/me/Dev/specrail`)를 쓰면 됩니다. 설치 후 Claude Code 세션을 새로 시작하세요.

## 스펙 워크플로

```text
/spec-requirements 로그인 기능 만들기   # 1. specs/user-login/requirements.md
  → 검토하고 "승인"
/spec-design                            # 2. specs/user-login/design.md
  → 검토하고 "승인"
/spec-tasks                             # 3. specs/user-login/tasks.md (체크리스트)
  → 검토하고 "승인"
/spec-impl                              # 4. 작업 하나 구현 → 확인 → 체크 → 보고
  → 검토하고 "계속" (또는 /spec-impl user-login 전부)
```

- 각 문서 맨 위에 `> 상태: 초안` 줄이 있습니다. 사용자가 승인하면 Claude가 `> 상태: 승인됨 (날짜)`로 바꿉니다. 앞 단계가 승인되지 않으면 다음 단계 스킬은 멈춥니다.
- 승인된 문서를 나중에 고치면 상태가 `초안`으로 돌아가고 다시 승인받습니다.
- 구현 중에 설계가 틀렸다는 것을 알게 되면, Claude는 코드를 스펙과 다르게 짜지 않고 멈춰서 design.md 수정을 제안합니다.
- 스킬 이름이 다른 플러그인과 겹치면 `/specrail:spec-design`처럼 앞에 `specrail:`을 붙입니다.

## 세션 메모리

```text
... 작업 ...
/session-save      # 작업 단위가 끝나면 인계 노트 저장 (처음 실행하면 .claude-memory/ 생성)
/clear             # 컨텍스트 비우기 → 인계 노트가 자동으로 다시 들어옴
/session-resume    # 더 자세히 복원하고 싶을 때
```

세션 메모리는 **프로젝트에 `.claude-memory/` 폴더가 있을 때만** 동작합니다. 처음 `/session-save`를 실행하면 폴더가 생깁니다. 그래서 다른 프로젝트에 파일이 함부로 생기지 않습니다.

| 시점 | 동작 |
|---|---|
| 세션 시작 · `/clear` · 재개 · 압축 직후 | 스펙 진행 상태(`specs/`가 있을 때), 메모리 규칙, 인계 노트, 최근 진행 로그, git 요약을 주입 |
| 압축 직전 | 변경 파일, 최근 요청, 마지막 응답, git 상태를 스냅샷으로 저장 (압축 직후 다시 주입) |
| 매 프롬프트 | 토큰 사용량이 기준을 넘으면 저장 제안 |
| 파일 수정 | 세션별 변경 파일 기록 |
| 세션 종료 | 세션 로그에 한 줄 기록 |

프로젝트에 생기는 파일:

```text
specs/<기능>/          requirements.md, design.md, tasks.md
.claude-memory/
  handoff.md          인계 노트
  progress.md         작업 로그
  decisions.md        결정 기록
  session-log.md      세션 종료 기록
  snapshots/          압축 스냅샷 (git 제외)
  .runtime/           세션별 변경 파일 기록 (git 제외)
  config.json         설정 (선택)
```

### 설정 (`.claude-memory/config.json`, 없으면 기본값)

| 키 | 기본값 | 설명 |
|---|---|---|
| `context_warn_tokens` | `150000` | 이 값을 넘으면 저장을 제안합니다. 1M 컨텍스트 모델이면 높이세요 |
| `handoff_inject_chars` | `4000` | 자동으로 넣을 인계 노트 길이(바이트) |
| `snapshot_keep` | `20` | 보관할 압축 스냅샷 수 |

## 구조

```text
.claude-plugin/marketplace.json   이 저장소가 마켓플레이스
plugin/
  .claude-plugin/plugin.json
  hooks/hooks.json                훅 등록
  hooks/*.sh                      훅 스크립트, 조회 도구 mem.sh
  rules/session-memory.md         SessionStart 훅이 출력하는 메모리 규칙
  skills/                         spec-* 4개, session-save, session-resume
```
