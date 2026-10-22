#!/usr/bin/env bash
# PreToolUse 훅 (Edit|Write|MultiEdit|NotebookEdit) — 스펙 승인 관문
# 승인 전 단계가 남은 스펙이 있는데 specs/ 밖의 프로젝트 파일을 고치려 하면 사용자에게 확인을 받는다.
# 막지 않고 묻는다: 스펙과 무관한 수정은 사용자가 허용하면 된다.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

FP="$(jget '.tool_input.file_path // .tool_input.notebook_path')"
[ -n "$FP" ] || exit 0
case "$FP" in /*) ;; *) FP="$ROOT/$FP";; esac
case "$FP" in
  "$ROOT"/specs/*|"$ROOT"/.claude-memory/*) exit 0;;   # 스펙 문서·세션 메모리는 언제나 허용
  "$ROOT"/*) ;;
  *) exit 0;;                                          # 프로젝트 밖 파일은 관여하지 않음
esac

PENDING="$(pending_specs)"
[ -n "$PENDING" ] || exit 0

REASON="specrail: 승인 전인 스펙이 있는데 코드를 고치려 합니다.
$(echo "$PENDING" | sed 's/^/- /')
스펙과 관계없는 수정이면 허용하세요. 스펙을 그만둘 거라면 specs/ 의 해당 폴더를 지우면 됩니다."
jq -n --arg r "$REASON" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "ask", permissionDecisionReason: $r}}'
exit 0
