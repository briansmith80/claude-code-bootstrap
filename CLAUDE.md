# Claude Code Bootstrap

## Project Overview

CLI tool that lets users quickly install pre-configured `.claude/settings.json` (or `settings.local.json`) into any project via a one-liner. Supports profiles for different project types (Laravel, Node, etc.).

## Conventions

- Pure bash — no external dependencies (no jq, no python, no node)
- POSIX-compatible where possible, bash-specific features allowed when necessary
- Cross-platform: macOS, Linux, Windows (Git Bash / MSYS2)
- All scripts use `#!/usr/bin/env bash` shebang
- Use `set -euo pipefail` in all scripts
- Quote all variables: `"${var}"` not `$var`
- Use `printf` over `echo` for portability
- Functions use lowercase_snake_case
- Constants use UPPER_SNAKE_CASE
- Indent with 2 spaces

## Repo Structure

```
profiles/           # JSON profile files fetched by the bootstrap script
  default.json      # Base profile — works for any project
  laravel.json      # Laravel-specific permissions and plugins
  node.json         # Node.js-specific permissions and plugins
install.sh              # One-liner installer (curl | bash) — installs claude-bootstrap shell function
claude-bootstrap.sh     # Main bootstrap script — applies profiles to projects
CLAUDE.md           # This file
README.md           # User-facing documentation
```

## Profile JSON Format

Profiles are standard Claude Code `settings.json` files. They may contain any valid Claude Code settings key including `permissions`, `enabledPlugins`, `statusLine`, etc.

## GitHub Raw URL Base

Profiles are fetched from: `https://raw.githubusercontent.com/briansmith80/claude-code-bootstrap/main/profiles/`

## Related Project

claude-code-status-bar (https://github.com/briansmith80/claude-code-status-bar) — the bootstrap tool can optionally configure the statusLine block from that project.
