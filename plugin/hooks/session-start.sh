#!/usr/bin/env bash
# SessionStart 훅 (startup | resume | clear | compact)
# - specs/ 가 있으면: 진행 중인 스펙 규칙과 스펙별 단계 상태
# - .claude-memory/ 가 있으면: 세션 메모리 규칙, 인계 노트, (압축 직후라면) 스냅샷, 진행 로그, git 상태
# 플러그인은 rules 파일을 로드하지 않으므로 규칙도 여기서 출력한다.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
SPECS="$(spec_status)"
[ -d "$MEM_DIR" ] || [ -n "$SPECS" ] || exit 0
HERE="$(dirname "${BASH_SOURCE[0]}")"

SOURCE="$(jget .source)"
HANDOFF_CHARS="$(cfg handoff_inject_chars 4000)"

{
  if [ -n "$SPECS" ]; then
    cat "$HERE/../rules/spec-workflow.md"
    echo "$SPECS"
    echo
  fi
  if [ -d "$MEM_DIR" ]; then
    cat "$HERE/../rules/session-memory.md"
    echo
    echo "## 🔁 이전 세션 맥락 (SessionStart: ${SOURCE:-unknown})"
    if [ -s "$MEM_DIR/handoff.md" ]; then
      echo; echo "### 인계 노트 (.claude-memory/handoff.md)"; clip_file "$HANDOFF_CHARS" "$MEM_DIR/handoff.md"
    fi
    if [ "$SOURCE" = "compact" ]; then
      SNAP="$(ls -t "$MEM_DIR"/snapshots/*-compact-*.md 2>/dev/null | head -n 1)"
      [ -n "$SNAP" ] && { echo; echo "### 압축 직전 자동 스냅샷 (${SNAP#"$ROOT"/})"; clip_file 3000 "$SNAP"; }
    fi
    P="$(recent_progress 8)"
    [ -n "$P" ] && { echo; echo "### 최근 진행 로그 (.claude-memory/progress.md)"; echo "$P"; }
    G="$(git_summary)"
    [ -n "$G" ] && { echo; echo "### Git"; echo "$G"; }
    echo
    case "$SOURCE" in
      compact) echo "→ 방금 컨텍스트가 압축되었다. 위 스냅샷과 노트로 맥락을 복원하고, 진행 중이던 작업의 관련 파일을 다시 읽은 뒤 이어서 진행하라.";;
      *)       echo "→ 위 맥락을 기준으로 이어서 작업하라. 노트의 내용은 실제 파일과 대조해 확인하라. 상세 복원은 /session-resume.";;
    esac
  fi
} | head -c 9500
exit 0
