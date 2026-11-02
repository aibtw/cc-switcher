# cc: run Claude Code, optionally switching account first (see claude-account)
#   cc              run with the active account
#   cc work [...]   switch to "work", then run claude with the remaining arguments
cc() {
  if [[ $# -gt 0 && "$1" != -* ]]; then
    claude-account use "$1" || return
    shift
  fi
  command claude "$@"
  local rc=$?
  claude-account sync >/dev/null
  return $rc
}
