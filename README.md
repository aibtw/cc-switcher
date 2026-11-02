# cc-switcher

Switch Claude Code between your work, personal, and hobby accounts on one machine while everything else stays shared: conversation history, `/resume`, settings, `CLAUDE.md`, memory, skills, plugins, MCP servers.

```
cc work        # switch to "work" and start Claude Code
cc hobby -c    # switch to "hobby", start Claude Code with -c
cc             # start Claude Code with the active account
claude-account # list saved accounts, * marks the active one
```

Linux only.

## Install

Requires Claude Code and `python3`.

```
git clone <repo-url> ~/cc-switcher
cd ~/cc-switcher
./install.sh
source ~/.bashrc
```

The installer puts `claude-account` in `~/.local/bin` and adds the `cc` command to `~/.bashrc` (and `~/.zshrc` if present). Run it again after pulling updates.

## First use

1. Save the login you already have under a name: `claude-account save work`
2. Add another account: `cc personal`. Claude Code signs out and asks for a browser login; that login is saved as `personal`.
3. Repeat for each account (`cc hobby`, ...). From then on `cc work` / `cc personal` / `cc hobby` switch without logging in again.

Names are free-form, any number of accounts.

## How it works

Claude Code keeps the login in two places:

- `~/.claude/.credentials.json`: the login tokens
- `oauthAccount` in `~/.claude.json`: which account those tokens belong to

`claude-account` keeps a copy of both per account in `~/.claude/accounts/<name>/` and swaps them in. Nothing else is touched, so all other data stays shared.

On every switch it first saves the live login of the account you are leaving, because Claude Code renews tokens while it runs and an older copy may stop working. `cc` also saves it when Claude Code exits.

Claude Code sessions that are already open follow a switch: each one checks the credentials file before its next request and reloads it when it changed.

## Commands

| Command | Does |
|---|---|
| `cc <name> [args]` | switch to `<name>` (new name: sign out and save the next login as `<name>`), then run `claude [args]` |
| `claude-account` | list saved accounts |
| `claude-account use <name>` | switch only, without starting Claude Code |
| `claude-account save <name>` | save the current login as `<name>` |
| `claude-account sync` | save the live login back to its account |
| `claude-account import <name> <dir>` | save the login from a separate `CLAUDE_CONFIG_DIR` folder |

## Troubleshooting

**`cc` still behaves the old way.** Each open terminal reads `~/.bashrc` once at start. Run `source ~/.bashrc` there, or open a new terminal. `type cc` must show `claude-account use`.

**An open session still shows the old account.** The session reloads the login at its next request. Send a message, then check `/usage` or `/status`.

**Asked to log in again for a saved account.** Each saved login expires after about a month unused. Log in again; the new login is saved under the same name.

**Warning "current login is not saved under any name".** You logged in without `cc` (for example `/login` inside Claude Code). Run `claude-account save <name>` before switching away, or that login is dropped.

**Every other open session lost its login.** While a new account waits for its first browser login, the machine has no login at all. Finish the login and the sessions continue.

**`CLAUDE_CONFIG_DIR` is set.** Unset it. cc-switcher works on the default `~/.claude` folder.

**`cc` hides the C compiler.** Only in interactive shells; builds and scripts are unaffected. Use `command cc` to reach the compiler.

## Uninstall

```
./install.sh --uninstall
```

Saved logins stay in `~/.claude/accounts/`; delete that folder to remove them.
