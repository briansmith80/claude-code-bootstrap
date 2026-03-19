#!/usr/bin/env bash
#
# claude-init — Bootstrap Claude Code settings for any project
#
# Usage:
#   claude-init [profile] [options]
#   claude-init laravel
#   claude-init --list
#   claude-init --statusline
#
# Profiles: default, laravel, node (fetched from GitHub)

set -euo pipefail

# ── Constants ──────────────────────────────────────────────────
REPO_RAW="https://raw.githubusercontent.com/briansmith80/claude-code-bootstrap/main"
PROFILES_URL="${REPO_RAW}/profiles"
AVAILABLE_PROFILES=("default" "laravel" "node")
VERSION="0.1.0"

# Detect if running from the repo (local profiles available)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_PROFILES_DIR="${SCRIPT_DIR}/profiles"

# ── Colors ─────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  BOLD="\033[1m"
  DIM="\033[2m"
  GREEN="\033[32m"
  YELLOW="\033[33m"
  CYAN="\033[36m"
  RED="\033[31m"
  RESET="\033[0m"
else
  BOLD="" DIM="" GREEN="" YELLOW="" CYAN="" RED="" RESET=""
fi

# ── Helpers ────────────────────────────────────────────────────
info()  { printf "${GREEN}%s${RESET} %s\n" ">" "$1"; }
warn()  { printf "${YELLOW}%s${RESET} %s\n" "!" "$1"; }
error() { printf "${RED}%s${RESET} %s\n" "x" "$1" >&2; }
dim()   { printf "${DIM}%s${RESET}\n" "$1"; }

usage() {
  cat <<EOF
${BOLD}claude-init${RESET} v${VERSION} — Bootstrap Claude Code project settings

${BOLD}Usage:${RESET}
  claude-init [profile] [options]

${BOLD}Profiles:${RESET}
  default     Common git + filesystem permissions
  laravel     PHP/Laravel tools (artisan, composer, pest, pint)
  node        Node.js tools (npm, yarn, pnpm, eslint, vitest)

${BOLD}Options:${RESET}
  --local           Write to settings.local.json instead of settings.json
  --statusline      Also configure claude-code-status-bar
  --list            List available profiles
  --force           Overwrite existing settings without prompting
  --backup          Back up existing settings before overwriting
  --merge           Merge profile into existing settings (requires node or python)
  --help, -h        Show this help
  --version, -v     Show version

${BOLD}Examples:${RESET}
  claude-init                    # interactive profile picker
  claude-init laravel            # apply Laravel profile
  claude-init node --local       # write to settings.local.json
  claude-init default --merge    # merge into existing settings
EOF
}

# ── HTTP fetch ─────────────────────────────────────────────────
fetch_url() {
  local url="$1"
  if command -v curl > /dev/null 2>&1; then
    curl -fsSL "$url"
  elif command -v wget > /dev/null 2>&1; then
    wget -qO- "$url"
  else
    error "curl or wget is required."
    exit 1
  fi
}

# ── Profile picker ─────────────────────────────────────────────
pick_profile() {
  printf "\n${BOLD}Available profiles:${RESET}\n\n"
  local i=1
  for p in "${AVAILABLE_PROFILES[@]}"; do
    case "$p" in
      default) desc="Common git + filesystem permissions" ;;
      laravel) desc="PHP/Laravel tools (artisan, composer, pest, pint)" ;;
      node)    desc="Node.js tools (npm, yarn, pnpm, eslint, vitest)" ;;
      *)       desc="" ;;
    esac
    printf "  ${CYAN}%d)${RESET} ${BOLD}%-12s${RESET} %s\n" "$i" "$p" "$desc"
    ((i++))
  done

  printf "\n"
  read -rp "Select a profile [1-${#AVAILABLE_PROFILES[@]}]: " choice

  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#AVAILABLE_PROFILES[@]} )); then
    PROFILE="${AVAILABLE_PROFILES[$((choice - 1))]}"
  else
    error "Invalid selection."
    exit 1
  fi
}

# ── JSON merge (needs node or python) ──────────────────────────
merge_json() {
  local existing="$1"
  local incoming="$2"
  local output="$3"

  if command -v node > /dev/null 2>&1; then
    node -e "
      const fs = require('fs');
      const base = JSON.parse(fs.readFileSync(process.argv[1], 'utf8'));
      const overlay = JSON.parse(process.argv[2]);

      // Deep merge permissions.allow arrays
      if (overlay.permissions && overlay.permissions.allow) {
        if (!base.permissions) base.permissions = {};
        if (!base.permissions.allow) base.permissions.allow = [];
        const existing = new Set(base.permissions.allow);
        for (const perm of overlay.permissions.allow) {
          existing.add(perm);
        }
        base.permissions.allow = [...existing].sort();
      }

      // Deep merge permissions.deny arrays
      if (overlay.permissions && overlay.permissions.deny) {
        if (!base.permissions) base.permissions = {};
        if (!base.permissions.deny) base.permissions.deny = [];
        const existing = new Set(base.permissions.deny);
        for (const perm of overlay.permissions.deny) {
          existing.add(perm);
        }
        base.permissions.deny = [...existing].sort();
      }

      // Merge other top-level keys (overlay wins)
      for (const key of Object.keys(overlay)) {
        if (key !== 'permissions') {
          base[key] = overlay[key];
        }
      }

      fs.writeFileSync(process.argv[3], JSON.stringify(base, null, 2) + '\n');
    " "$existing" "$incoming" "$output"
    return 0
  elif command -v python3 > /dev/null 2>&1 || command -v python > /dev/null 2>&1; then
    local py
    py=$(command -v python3 || command -v python)
    "$py" -c "
import json, sys

with open(sys.argv[1]) as f:
    base = json.load(f)
overlay = json.loads(sys.argv[2])

# Deep merge permissions.allow arrays
if 'permissions' in overlay:
    if 'permissions' not in base:
        base['permissions'] = {}
    for key in ('allow', 'deny'):
        if key in overlay['permissions']:
            existing = set(base.get('permissions', {}).get(key, []))
            existing.update(overlay['permissions'][key])
            base.setdefault('permissions', {})[key] = sorted(existing)

# Merge other top-level keys (overlay wins)
for key in overlay:
    if key != 'permissions':
        base[key] = overlay[key]

with open(sys.argv[3], 'w') as f:
    json.dump(base, f, indent=2)
    f.write('\n')
" "$existing" "$incoming" "$output"
    return 0
  else
    return 1
  fi
}

# ── Statusline setup ──────────────────────────────────────────
setup_statusline() {
  local settings_file="$1"
  local script_path="${HOME}/.claude/statusline-command.sh"
  local statusline_url="https://raw.githubusercontent.com/briansmith80/claude-code-status-bar/main"

  info "Setting up claude-code-status-bar..."

  # Download the statusline script if not already installed
  if [[ ! -f "$script_path" ]]; then
    fetch_url "${statusline_url}/statusline-command.sh" > "$script_path"
    chmod +x "$script_path"
    info "Downloaded statusline script to ${script_path}"
  else
    dim "  Statusline script already installed at ${script_path}"
  fi

  # Add statusLine config to the settings file
  local command_value="bash ${script_path}"
  local statusline_json="{\"type\":\"command\",\"command\":\"${command_value}\"}"

  if grep -q '"statusLine"' "$settings_file" 2>/dev/null; then
    dim "  statusLine already configured in settings — skipped."
  elif command -v node > /dev/null 2>&1; then
    node -e "
      const fs = require('fs');
      const data = JSON.parse(fs.readFileSync(process.argv[1], 'utf8'));
      data.statusLine = { type: 'command', command: process.argv[2] };
      fs.writeFileSync(process.argv[1], JSON.stringify(data, null, 2) + '\n');
    " "$settings_file" "$command_value"
    info "Added statusLine config to settings."
  elif command -v python3 > /dev/null 2>&1 || command -v python > /dev/null 2>&1; then
    local py
    py=$(command -v python3 || command -v python)
    "$py" -c "
import json, sys
path, cmd = sys.argv[1], sys.argv[2]
with open(path) as f: data = json.load(f)
data['statusLine'] = {'type': 'command', 'command': cmd}
with open(path, 'w') as f: json.dump(data, f, indent=2); f.write('\n')
" "$settings_file" "$command_value"
    info "Added statusLine config to settings."
  else
    warn "Could not add statusLine automatically (no node or python found)."
    printf "  Add this to %s manually:\n\n" "$settings_file"
    printf "    \"statusLine\": { \"type\": \"command\", \"command\": \"%s\" }\n\n" "$command_value"
  fi
}

# ── Main ───────────────────────────────────────────────────────
main() {
  local profile=""
  local use_local=false
  local force=false
  local backup=false
  local merge=false
  local statusline=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --local)      use_local=true ;;
      --force)      force=true ;;
      --backup)     backup=true ;;
      --merge)      merge=true ;;
      --statusline) statusline=true ;;
      --list)
        printf "\nAvailable profiles:\n"
        for p in "${AVAILABLE_PROFILES[@]}"; do
          printf "  %s\n" "$p"
        done
        exit 0
        ;;
      --help|-h)    usage; exit 0 ;;
      --version|-v) printf "claude-init v%s\n" "$VERSION"; exit 0 ;;
      -*)
        error "Unknown option: $1"
        usage
        exit 1
        ;;
      *)
        if [[ -z "$profile" ]]; then
          profile="$1"
        else
          error "Too many arguments."
          usage
          exit 1
        fi
        ;;
    esac
    shift
  done

  # Header
  printf "\n${BOLD}claude-init${RESET} v${VERSION}\n\n"

  # Select profile
  if [[ -z "$profile" ]]; then
    pick_profile
  else
    PROFILE="$profile"
  fi

  # Validate profile name
  local valid=false
  for p in "${AVAILABLE_PROFILES[@]}"; do
    if [[ "$p" == "$PROFILE" ]]; then
      valid=true
      break
    fi
  done

  if [[ "$valid" != "true" ]]; then
    error "Unknown profile: ${PROFILE}"
    printf "  Available: %s\n" "${AVAILABLE_PROFILES[*]}"
    exit 1
  fi

  info "Using profile: ${PROFILE}"

  # Determine target file
  local target_dir=".claude"
  local target_file
  if [[ "$use_local" == "true" ]]; then
    target_file="${target_dir}/settings.local.json"
  else
    target_file="${target_dir}/settings.json"
  fi

  # Fetch profile (local first, then remote)
  local profile_json
  local local_file="${LOCAL_PROFILES_DIR}/${PROFILE}.json"

  if [[ -f "$local_file" ]]; then
    info "Loading profile from local: ${local_file}"
    profile_json=$(cat "$local_file")
  else
    info "Fetching profile from remote..."
    profile_json=$(fetch_url "${PROFILES_URL}/${PROFILE}.json")
  fi

  if [[ -z "$profile_json" ]]; then
    error "Failed to fetch profile: ${PROFILE}"
    exit 1
  fi

  # Create .claude directory
  mkdir -p "$target_dir"

  # Handle existing settings
  if [[ -f "$target_file" ]]; then
    if [[ "$force" == "true" ]]; then
      warn "Overwriting ${target_file} (--force)"
    elif [[ "$backup" == "true" ]]; then
      local backup_file="${target_file}.backup.$(date +%Y%m%d%H%M%S)"
      cp "$target_file" "$backup_file"
      info "Backed up to ${backup_file}"
    elif [[ "$merge" == "true" ]]; then
      info "Merging profile into existing ${target_file}..."
      if merge_json "$target_file" "$profile_json" "$target_file"; then
        info "Merged successfully."
        if [[ "$statusline" == "true" ]]; then
          setup_statusline "$target_file"
        fi
        printf "\n${GREEN}Done!${RESET} Settings updated at ${BOLD}${target_file}${RESET}\n\n"
        return 0
      else
        error "Merge requires node or python. Use --force or --backup instead."
        exit 1
      fi
    else
      warn "${target_file} already exists."
      printf "\n  Options:\n"
      printf "    ${CYAN}--force${RESET}    Overwrite existing file\n"
      printf "    ${CYAN}--backup${RESET}   Back up existing, then overwrite\n"
      printf "    ${CYAN}--merge${RESET}    Merge permissions (requires node or python)\n"
      printf "\n"
      read -rp "Overwrite? [y/N]: " answer
      if [[ "${answer,,}" != "y" ]]; then
        info "Skipped. No changes made."
        exit 0
      fi
    fi
  fi

  # Write settings
  printf "%s\n" "$profile_json" > "$target_file"
  info "Written to ${target_file}"

  # Optional statusline setup
  if [[ "$statusline" == "true" ]]; then
    setup_statusline "$target_file"
  fi

  printf "\n${GREEN}Done!${RESET} Claude Code settings applied at ${BOLD}${target_file}${RESET}\n\n"
}

main "$@"
