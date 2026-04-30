#!/usr/bin/env bash
# pre-tool-use-personal-lock.sh
#
# Hard-locks personal/ as read-only. Blocks Write, Edit, MultiEdit,
# NotebookEdit, and best-effort blocks Bash mutation shapes targeting
# personal/. Reads (Read, Glob, Grep, read-only Bash) are allowed.
#
# Best-effort safety, not a security boundary. Documented in the plan.
#
# Hook input arrives on stdin as JSON.
# Permission decision contract: exit 0 + stdout JSON to allow/deny.

set -u

input="$(cat)"
[[ -z "$input" ]] && exit 0

# Pure-bash field extraction; sub-millisecond.
tool=""
re_tool='"tool_name"[[:space:]]*:[[:space:]]*"([^"]*)"'
[[ "$input" =~ $re_tool ]] && tool="${BASH_REMATCH[1]}"

deny() {
  cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"$1"}}
EOF
  exit 0
}

# --- File-write tools: deny if path is under personal/ ----------------------
case "$tool" in
  Write|Edit|MultiEdit|NotebookEdit)
    path=""
    re_path='"file_path"[[:space:]]*:[[:space:]]*"([^"]*)"'
    re_npath='"notebook_path"[[:space:]]*:[[:space:]]*"([^"]*)"'
    [[ "$input" =~ $re_path  ]] && path="${BASH_REMATCH[1]}"
    [[ -z "$path" && "$input" =~ $re_npath ]] && path="${BASH_REMATCH[1]}"
    case "$path" in
      */personal/*|personal/*|personal)
        deny "personal/ is read-only. Operator-only zone."
        ;;
    esac
    exit 0
    ;;
  Bash)
    cmd=""
    re_cmd='"command"[[:space:]]*:[[:space:]]*"((\\.|[^"\\])*)"'
    [[ "$input" =~ $re_cmd ]] && cmd="${BASH_REMATCH[1]}"
    [[ -z "$cmd" ]] && exit 0

    # If the command does not mention personal/, allow it.
    case "$cmd" in
      *personal*) ;;
      *) exit 0 ;;
    esac

    # Block obvious mutation shapes against personal/.
    # Patterns intentionally conservative; they're not a security boundary.
    if printf '%s' "$cmd" | grep -Eq '(^|[[:space:]/])(rm|mv|cp|tee|touch|mkdir|rmdir|chmod|chown|sed[[:space:]]+-i)([[:space:]]|$)' \
         || printf '%s' "$cmd" | grep -Eq '>[[:space:]]*[^|&]*personal' \
         || printf '%s' "$cmd" | grep -Eq '>>[[:space:]]*[^|&]*personal' \
         || printf '%s' "$cmd" | grep -Eq '<<[[:space:]]*[A-Z_]+[^|]*personal'; then
      deny "Bash mutation against personal/ is blocked. Use Read for personal/ content."
    fi

    exit 0
    ;;
  *)
    exit 0
    ;;
esac
