# claude-code-bootstrap

One-liner setup tool for Claude Code project settings. Apply pre-configured permission profiles to any project in seconds.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/briansmith80/claude-code-bootstrap/main/install.sh | bash
```

This installs the `claude-init` command and adds a shell alias.

## Usage

```bash
cd your-project
claude-init              # interactive profile picker
claude-init laravel      # apply a specific profile
claude-init node --local # write to settings.local.json
```

### Profiles

| Profile   | Description                                          |
|-----------|------------------------------------------------------|
| `default` | Common git + filesystem permissions                  |
| `laravel` | PHP/Laravel tools (artisan, composer, pest, pint)    |
| `node`    | Node.js tools (npm, yarn, pnpm, eslint, vitest)     |

### Options

```
--local           Write to settings.local.json instead of settings.json
--statusline      Also configure claude-code-status-bar
--force           Overwrite existing settings without prompting
--backup          Back up existing settings before overwriting
--merge           Merge profile into existing settings (requires node or python)
--list            List available profiles
--help, -h        Show help
--version, -v     Show version
```

### Existing Settings

If `.claude/settings.json` already exists, `claude-init` will prompt before overwriting. You can:

- `--force` — overwrite without asking
- `--backup` — create a timestamped backup, then overwrite
- `--merge` — merge the profile's permissions into your existing settings (requires `node` or `python`)

### Statusline Integration

Use `--statusline` to also install and configure [claude-code-status-bar](https://github.com/briansmith80/claude-code-status-bar):

```bash
claude-init laravel --statusline
```

This downloads the statusline script and adds the `statusLine` block to your settings.

## Run Without Installing

Apply a profile directly without installing:

```bash
curl -fsSL https://raw.githubusercontent.com/briansmith80/claude-code-bootstrap/main/claude-init.sh | bash -s -- laravel
```

## Profiles

Profiles are standard Claude Code `settings.json` files stored in the [`profiles/`](profiles/) directory. Each profile defines permissions appropriate for a given project type.

### Creating Custom Profiles

Fork this repo and add your own JSON files to `profiles/`. The format is a standard Claude Code settings object:

```json
{
  "permissions": {
    "allow": [
      "Bash(git status)",
      "Bash(npm install)"
    ],
    "deny": []
  }
}
```

## Requirements

- `bash` (macOS, Linux, Git Bash, or MSYS2)
- `curl` or `wget`
- `node` or `python` (only needed for `--merge`)

## License

MIT
