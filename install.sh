#!/usr/bin/env bash
# Install cc-switcher for the current user.
#   ./install.sh             install or update
#   ./install.sh --uninstall remove the program and the rc-file lines (saved logins stay)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
SHARE_DIR="$HOME/.local/share/cc-switcher"
BEGIN="# >>> cc-switcher >>>"
END="# <<< cc-switcher <<<"

rc_files() {
  echo "$HOME/.bashrc"
  [[ -f "$HOME/.zshrc" ]] && echo "$HOME/.zshrc"
  return 0
}

remove_block() {
  local rc="$1"
  [[ -f "$rc" ]] || return 0
  sed -i "/^$BEGIN\$/,/^$END\$/d" "$rc"
}

if [[ "${1:-}" == "--uninstall" ]]; then
  rm -f "$BIN_DIR/claude-account"
  rm -rf "$SHARE_DIR"
  for rc in $(rc_files); do remove_block "$rc"; done
  echo "removed; saved logins remain in ~/.claude/accounts/"
  exit 0
fi

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "error: Linux only (on macOS Claude Code keeps the login in the Keychain, not in a file)" >&2
  exit 1
fi
command -v python3 >/dev/null || { echo "error: python3 is required" >&2; exit 1; }
command -v claude >/dev/null || echo "warning: claude not found on PATH; install Claude Code first" >&2

install -d "$BIN_DIR" "$SHARE_DIR"
install -m 755 "$REPO/bin/claude-account" "$BIN_DIR/claude-account"
install -m 644 "$REPO/shell/cc.sh" "$SHARE_DIR/cc.sh"

for rc in $(rc_files); do
  touch "$rc"
  remove_block "$rc"
  if grep -qE '^[[:space:]]*(function[[:space:]]+)?cc[[:space:]]*\(\)' "$rc"; then
    echo "warning: $rc already defines a cc function; the cc-switcher one, added at the end, wins" >&2
  fi
  [[ -s "$rc" && "$(tail -c1 "$rc")" != "" ]] && echo >> "$rc"
  # shellcheck disable=SC2016  # $HOME is expanded when the rc file runs
  printf '%s\n[ -f "$HOME/.local/share/cc-switcher/cc.sh" ] && . "$HOME/.local/share/cc-switcher/cc.sh"\n%s\n' \
    "$BEGIN" "$END" >> "$rc"
  echo "updated $rc"
done

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "warning: $BIN_DIR is not on PATH; add it in your shell rc file" >&2 ;;
esac

echo "installed. Open a new terminal (or run: source ~/.bashrc), then: claude-account"
