# c-cli

Natural language to shell commands, powered by [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

```
$ c show disk usage sorted by size
> du -sh * | sort -rh
4.2G    node_modules
1.1G    .git
256M    data
[1s]
```

## Install

```bash
curl -sS https://raw.githubusercontent.com/ypankovych/c-cli/main/install.sh | bash
```

**Requires:** [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) (`claude` command must be available)

## Commands

| Command | Description |
|---------|-------------|
| `c <request>` | Translate and execute |
| `cx <request>` | Translate and print (don't execute) |
| `cc <request>` | Translate and copy to clipboard |

## Features

- Translates natural language to shell commands using Claude
- Asks for confirmation before running destructive commands (`rm -rf`, `kill -9`, etc.)
- Auto-retry on failure — sends the error back to Claude for a corrected command
- Adds executed commands to shell history (arrow keys recall the actual command)
- Logs all translations to `~/.c_history`
- Pipe-friendly — status output goes to stderr
- Works with both **zsh** and **bash**
- Clipboard support: macOS (`pbcopy`), Linux (`xclip`/`xsel`/`wl-copy`)

## Examples

```bash
c list all running docker containers
c find python files larger than 1MB
c compress the logs directory into a tar.gz
c what is my public ip
cx show git log as a graph          # just prints the command
cc count lines of code in src       # copies to clipboard
```

## Uninstall

```bash
~/.c-cli/uninstall.sh
```

## License

MIT
