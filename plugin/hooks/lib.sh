#!/usr/bin/env bash
# specrail 공통 헬퍼 — 훅과 mem.sh 가 source 한다.
# 원칙: 어떤 경우에도 Claude 작업을 깨뜨리지 않는다(실패 시 조용히 exit 0).
# 메모리는 프로젝트의 .claude-memory/ 에 저장된다. 이 폴더가 없으면 기록·주입하지 않는다(프로젝트별 opt-in).

command -v jq >/dev/null 2>&1 || exit 0

HOOK_INPUT=""
[ -n "${KIT_NO_STDIN:-}" ] || HOOK_INPUT="$(cat 2>/dev/null || true)"
jget() { printf '%s' "$HOOK_INPUT" | jq -r "$1 // empty" 2>/dev/null; }

ROOT="${CLAUDE_PROJECT_DIR:-$(jget .cwd)}"
ROOT="${ROOT:-$PWD}"
MEM_DIR="$ROOT/.claude-memory"
RUNTIME_DIR="$MEM_DIR/.runtime"
CONFIG="$MEM_DIR/config.json"

# cfg <key> <default>
cfg() {
  local v
  v="$(jq -r --arg k "$1" '.[$k] | if . == null then empty else tostring end' "$CONFIG" 2>/dev/null)"
  echo "${v:-$2}"
}

session_dir() { local sid; sid="$(jget .session_id)"; echo "$RUNTIME_DIR/sessions/${sid:-unknown}"; }

# clip_file <max-bytes> <file> — 줄 단위로 잘라 출력 (멀티바이트 깨짐 방지)
clip_file() {
  local n="$1" f="$2" size
  [ -f "$f" ] || return 0
  size="$(wc -c < "$f" | tr -d ' ')"
  if [ "$size" -le "$n" ]; then cat "$f"; else head -c "$n" "$f" | sed '$d'; echo; echo "…(이하 생략 — 전체: ${f#"$ROOT"/})"; fi
}

# git 저장소면 브랜치·최근 커밋·미커밋 변경 수 요약
git_summary() {
  git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  echo "- 브랜치: $(git -C "$ROOT" branch --show-current 2>/dev/null)"
  echo "- 커밋 안 된 변경: $(git -C "$ROOT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')개"
  echo "- 최근 커밋:"
  git -C "$ROOT" log --oneline -3 2>/dev/null | sed 's/^/  - /'
}

recent_progress() { grep -E '^(- |### )[0-9]{4}-' "$MEM_DIR/progress.md" 2>/dev/null | tail -n "${1:-8}"; }

# specs/<기능>/ 마다 단계 문서의 상태(> 상태: …)와 작업 진행률 요약
spec_status() {
  local d f line st done total
  for d in "$ROOT"/specs/*/; do
    [ -d "$d" ] || continue
    line="- $(basename "$d"):"
    for f in requirements design tasks; do
      [ -f "$d$f.md" ] || continue
      st="$(sed -n 's/^> 상태: *\([^ ]*\).*/\1/p' "$d$f.md" | head -n 1)"
      line="$line $f(${st:-?})"
    done
    if [ -f "${d}tasks.md" ]; then
      done="$(grep -cE '^[[:space:]]*- \[[xX]\]' "${d}tasks.md")"
      total="$(grep -cE '^[[:space:]]*- \[[ xX]\]' "${d}tasks.md")"
      line="$line · 작업 $done/$total"
    fi
    echo "$line"
  done
}
