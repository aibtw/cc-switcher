# cc-switcher: agent notes

Switches the Claude Code login between saved accounts on Linux; all other Claude Code data stays shared. User-facing docs: `README.md`.

## Layout

- `bin/claude-account`: Python 3, standard library only. All logic lives here.
- `shell/cc.sh`: the `cc` shell function (bash and zsh). Calls `claude-account use`, runs `claude`, then `claude-account sync`.
- `install.sh`: copies `bin/claude-account` to `~/.local/bin` and `shell/cc.sh` to `~/.local/share/cc-switcher/`; adds a source line between `# >>> cc-switcher >>>` / `# <<< cc-switcher <<<` markers in `~/.bashrc` and `~/.zshrc`. Re-running replaces the block. `--uninstall` removes the files and the block.
- `tests/test.sh`: runs `claude-account` against a temporary fake `HOME` with made-up logins.

## Claude Code internals relied on

- Login tokens: `~/.claude/.credentials.json` (`{"claudeAiOauth": {...}}`). Linux only; macOS uses the Keychain.
- Account profile: the `oauthAccount` key in `~/.claude.json`. Only that key is replaced; the rest of the file holds shared state and must survive every write.
- Open sessions compare the credentials file's modification time before each API request and reload it when it changed. Found by reading the Claude Code 2.1.309 bundle (`lastCredentialsMtimeMs`); re-check after Claude Code updates if switching stops reaching open sessions.
- Refresh tokens rotate, so the live credentials must be saved back to the outgoing account before every switch (`save_live`).
- The default `~/.claude` folder is assumed; `CLAUDE_CONFIG_DIR` is not supported.

## Rules

- Never run `claude-account use` against the real `HOME` while testing: it moves every open session on the machine to another account. Test with `tests/test.sh` or `HOME=<tmp dir> bin/claude-account ...`.
- Write credential files with mode 600 and account folders with mode 700, through `write_json` (temp file + rename).
- Account identity is `(accountUuid, organizationUuid)`; the same email can belong to several organizations.
- After changing behavior or commands, update `README.md` (commands table, troubleshooting) in the same commit.
- Commit messages: `type(scope): summary`. No `Co-Authored-By` lines.

## Check

```
bash tests/test.sh
```
