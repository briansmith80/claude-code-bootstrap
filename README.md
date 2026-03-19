# claude-code-bootstrap

One-liner setup tool for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) project settings. Apply pre-configured permission profiles to any project in seconds — no manual JSON editing required.

## What It Does

When you use Claude Code in a project, it reads `.claude/settings.json` to know which commands it's allowed to run without asking you for permission every time. This tool gives you ready-made profiles so you don't have to build that settings file by hand.

Each profile includes:

- **Allowed commands** — git, filesystem tools, and language-specific CLIs (e.g. `npm`, `composer`)
- **Denied commands** — dangerous operations like `rm -rf /`, `git push --force`, `chmod 777`
- **Plugins** — recommended Claude Code plugins for your stack
- **Effort level** — set to `high` for thorough responses

## Quick Start

### 1. Install

```bash
curl -fsSL https://raw.githubusercontent.com/briansmith80/claude-code-bootstrap/main/install.sh | bash
```

This downloads `claude-bootstrap` to `~/.claude-bootstrap/` and adds a shell alias to your `.bashrc` / `.zshrc`.

### 2. Use

```bash
cd your-project
claude-bootstrap
```

That's it. You'll get an interactive menu to pick a profile. Or pass one directly:

```bash
claude-bootstrap laravel
```

## Profiles

| Profile   | What It Adds                                                      |
|-----------|-------------------------------------------------------------------|
| `default` | Git, filesystem tools, curl/wget, gh CLI                          |
| `laravel` | Everything in default + composer, artisan, pest, pint, phpstan, npm |
| `node`    | Everything in default + npm, yarn, pnpm, bun, eslint, prettier, jest, vitest, tsc |

All profiles share a common base of ~60 allowed commands (git operations, file utilities, archive tools). Language-specific profiles add their own tools on top.

### What Gets Denied

Every profile blocks these destructive operations:

```
chmod 777              git push --force / -f       rm -rf /
git clean -f           git reset --hard            rm -rf ~
```

The Laravel profile additionally blocks:

```
php artisan migrate:fresh     php artisan migrate:reset     php artisan db:wipe
```

### Included Plugins

| Plugin | default | laravel | node |
|--------|:-------:|:-------:|:----:|
| `compound-engineering` | x | x | x |
| `superpowers` | x | x | x |
| `laravel-boost` | | x | |
| `frontend-design` | | | x |
| `playwright` | | | x |

## Options

```
claude-bootstrap [profile] [options]
```

| Flag | Description |
|------|-------------|
| `--local` | Write to `settings.local.json` instead of `settings.json` (see below) |
| `--statusline` | Also install [claude-code-status-bar](https://github.com/briansmith80/claude-code-status-bar) |
| `--force` | Overwrite existing settings without prompting |
| `--backup` | Create a timestamped backup before overwriting |
| `--merge` | Merge profile into existing settings (requires `node` or `python`) |
| `--list` | List available profiles and exit |
| `--help`, `-h` | Show help |
| `--version`, `-v` | Show version |

### settings.json vs settings.local.json

Claude Code reads both files from the `.claude/` directory:

- **`settings.json`** — shared team settings, typically committed to git
- **`settings.local.json`** — personal overrides, typically gitignored

Use `--local` when you want to apply a profile just for yourself without affecting teammates:

```bash
claude-bootstrap node --local
```

### Merging Into Existing Settings

If you already have a `settings.json` with custom permissions, `--merge` adds the profile's permissions without replacing yours:

```bash
claude-bootstrap laravel --merge
```

How merge works:
- `permissions.allow` and `permissions.deny` arrays are **combined and deduplicated** (alphabetically sorted)
- Other top-level keys (like `enabledPlugins`, `effortLevel`) are **overwritten** by the profile's values
- Your existing non-overlapping settings are **preserved**

Merge requires `node` or `python3` to be installed. If neither is available, use `--backup` to save your current settings first, then overwrite.

### Statusline Integration

The `--statusline` flag downloads and configures [claude-code-status-bar](https://github.com/briansmith80/claude-code-status-bar), which adds a live status display to your Claude Code session:

```bash
claude-bootstrap laravel --statusline
```

This does two things:
1. Downloads `statusline-command.sh` to `~/.claude/statusline-command.sh`
2. Adds a `statusLine` block to your settings file

Requires `node` or `python` to modify the JSON. If neither is available, it prints manual instructions.

## Run Without Installing

Apply a profile directly without the installer:

```bash
curl -fsSL https://raw.githubusercontent.com/briansmith80/claude-code-bootstrap/main/claude-bootstrap.sh | bash -s -- laravel
```

You can pass any options after `--`:

```bash
curl -fsSL https://raw.githubusercontent.com/briansmith80/claude-code-bootstrap/main/claude-bootstrap.sh | bash -s -- node --local --statusline
```

## Creating Custom Profiles

1. Fork this repo
2. Add a JSON file to `profiles/` — the filename (without `.json`) becomes the profile name
3. Use this format:

```json
{
  "permissions": {
    "allow": [
      "Bash(git status)",
      "Bash(your-tool)"
    ],
    "deny": [
      "Bash(dangerous-command)"
    ]
  },
  "enabledPlugins": {
    "plugin-name@marketplace-id": true
  },
  "effortLevel": "high"
}
```

4. Update the `AVAILABLE_PROFILES` array in `claude-bootstrap.sh` and the `pick_profile()` descriptions

When running from a cloned repo, profiles are loaded from the local `profiles/` directory — no network fetch needed.

## Updating

Re-run the installer to update to the latest version:

```bash
curl -fsSL https://raw.githubusercontent.com/briansmith80/claude-code-bootstrap/main/install.sh | bash
```

The installer overwrites the script at `~/.claude-bootstrap/claude-bootstrap.sh` and skips the alias if it already exists.

## Uninstalling

```bash
# Remove the installed script
rm -rf ~/.claude-bootstrap

# Remove the alias from your shell config
# Edit ~/.bashrc, ~/.zshrc, or ~/.bash_profile and delete the lines:
#   # claude-code-bootstrap
#   alias claude-bootstrap='...'
```

This does **not** remove any `.claude/settings.json` files from your projects.

## Requirements

- **bash** — macOS, Linux, Git Bash, or MSYS2 on Windows
- **curl** or **wget** — for downloading profiles
- **node** or **python** — only needed for `--merge` and `--statusline` JSON editing

## Troubleshooting

**"command not found: claude-bootstrap"**
Restart your shell or run `source ~/.bashrc` (or `~/.zshrc`) to load the alias.

**"Failed to fetch profile"**
Check your internet connection. The script fetches profiles from GitHub. If you're behind a proxy, ensure `curl` or `wget` can reach `raw.githubusercontent.com`.

**"Invalid profile data received"**
The remote returned something other than JSON (likely a 404 page). Verify the profile name exists with `claude-bootstrap --list`.

**"Merge requires node or python"**
Install Node.js or Python, or use `--backup --force` to save your existing settings and overwrite.

**Settings not taking effect in Claude Code**
Make sure the `.claude/` directory is in your project root (where you run Claude Code from). Check that the JSON is valid — open the file and look for syntax errors.

## License

MIT
