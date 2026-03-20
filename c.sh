# c-cli — Natural language to shell commands powered by Claude
# https://github.com/ypankovych/c-cli
#
# Works with both zsh and bash. Requires: claude (Claude Code CLI)
#
# Commands:
#   c  <request>  — translate and execute
#   cx <request>  — translate and print (don't execute)
#   cc <request>  — translate and copy to clipboard

_c_prompt="You translate natural language into shell commands. ALWAYS prefer returning a command. Even for questions like 'is X running' or 'what is my IP' — return the command that answers it (e.g. 'docker info', 'curl ifconfig.me'). Respond with ONLY the raw command — no explanation, no markdown, no backticks, no alternatives. Only if the request is purely conceptual with absolutely no possible command (e.g. 'explain what TCP is'), prefix your response with NOT_A_COMMAND: followed by a brief answer."

_c_destructive_patterns='rm -rf|rm -r|rmdir|kill -9|killall|drop table|drop database|reset --hard|push --force|checkout -- \.|clean -fd|mkfs|dd if='

_c_clipboard() {
  if command -v pbcopy >/dev/null 2>&1; then
    pbcopy
  elif command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard
  elif command -v xsel >/dev/null 2>&1; then
    xsel --clipboard --input
  elif command -v wl-copy >/dev/null 2>&1; then
    wl-copy
  else
    echo "(clipboard not available — install pbcopy/xclip/xsel)" >&2
    return 1
  fi
}

_c_add_history() {
  if [ -n "$ZSH_VERSION" ]; then
    print -s "$1"
  elif [ -n "$BASH_VERSION" ]; then
    history -s "$1"
  fi
}

_c_translate() {
  local result
  result=$(claude -p "$_c_prompt User request: $*")
  # Strip markdown fences and inline backticks
  result=$(echo "$result" | sed '/^```/d' | sed 's/^`\(.*\)`$/\1/' | sed '/^$/d')
  # Join multi-line into single command
  result=$(echo "$result" | paste -sd' ' -)
  echo "$result"
}

# c — translate and execute
c() {
  if [ $# -eq 0 ]; then
    echo "Usage: c <natural language command>" >&2
    echo "  c list running docker containers" >&2
    echo "  cx ... (explain only)  cc ... (copy to clipboard)" >&2
    return 1
  fi

  local result
  result=$(_c_translate "$@")

  if [ "${result#NOT_A_COMMAND:}" != "$result" ]; then
    echo "${result#NOT_A_COMMAND: }"
    return
  fi

  # Log to history file
  echo "$(date '+%Y-%m-%d %H:%M:%S') | $* | $result" >> ~/.c_history

  # Destructive command confirmation
  if echo "$result" | grep -qEi "$_c_destructive_patterns"; then
    echo "Warning: $result" >&2
    printf "This looks destructive. Execute? [y/N] " >&2
    read -r confirm
    case "$confirm" in
      [yY]) ;;
      *) echo "Aborted." >&2; return 1 ;;
    esac
  fi

  echo "> $result" >&2
  _c_add_history "$result"
  local start_ts=$SECONDS
  eval "$result"
  local exit_code=$?
  local elapsed=$(( SECONDS - start_ts ))
  echo "[${elapsed}s]" >&2

  # Error retry
  if [ $exit_code -ne 0 ]; then
    printf "Command failed (exit %d). Retry with Claude? [y/N] " "$exit_code" >&2
    read -r retry
    if [ "$retry" = "y" ] || [ "$retry" = "Y" ]; then
      local fix
      fix=$(claude -p "$_c_prompt The previous command '$result' failed. User wanted: $*. Give a corrected command.")
      fix=$(echo "$fix" | sed '/^```/d' | sed 's/^`\(.*\)`$/\1/' | sed '/^$/d')
      echo "> $fix" >&2
      _c_add_history "$fix"
      echo "$(date '+%Y-%m-%d %H:%M:%S') | (retry) $* | $fix" >> ~/.c_history
      eval "$fix"
    fi
  fi
}

# cx — explain only, don't execute
cx() {
  if [ $# -eq 0 ]; then echo "Usage: cx <natural language command> (shows command without executing)" >&2; return 1; fi
  local result
  result=$(_c_translate "$@")
  if [ "${result#NOT_A_COMMAND:}" != "$result" ]; then
    echo "${result#NOT_A_COMMAND: }"
  else
    echo "$result"
  fi
}

# cc — translate and copy to clipboard
cc() {
  if [ $# -eq 0 ]; then echo "Usage: cc <natural language command> (copies command to clipboard)" >&2; return 1; fi
  local result
  result=$(_c_translate "$@")
  if [ "${result#NOT_A_COMMAND:}" != "$result" ]; then
    echo "${result#NOT_A_COMMAND: }"
  else
    echo "$result" | _c_clipboard
    echo "Copied: $result" >&2
  fi
}
