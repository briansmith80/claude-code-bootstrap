#!/usr/bin/env bash
#
# claude-code-bootstrap — Installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/briansmith80/claude-code-bootstrap/main/install.sh | bash
#
# Installs the claude-bootstrap command and optionally adds a shell alias.

set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/briansmith80/claude-code-bootstrap/main"
SCRIPT_NAME="claude-bootstrap.sh"
INSTALL_DIR="${HOME}/.claude-bootstrap"
INSTALL_PATH="${INSTALL_DIR}/${SCRIPT_NAME}"

# ── Colors ─────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  BOLD="\033[1m"
  GREEN="\033[32m"
  YELLOW="\033[33m"
  CYAN="\033[36m"
  RED="\033[31m"
  RESET="\033[0m"
else
  BOLD="" GREEN="" YELLOW="" CYAN="" RED="" RESET=""
fi

info()  { printf "${GREEN}%s${RESET} %s\n" ">" "$1"; }
warn()  { printf "${YELLOW}%s${RESET} %s\n" "!" "$1"; }
error() { printf "${RED}%s${RESET} %s\n" "x" "$1" >&2; }

# ── Header ─────────────────────────────────────────────────────
printf "\n${BOLD}claude-code-bootstrap${RESET} — Installer\n\n"

# ── Download ───────────────────────────────────────────────────
mkdir -p "$INSTALL_DIR"

if command -v curl > /dev/null 2>&1; then
  curl -fsSL "${REPO_RAW}/${SCRIPT_NAME}" -o "$INSTALL_PATH"
elif command -v wget > /dev/null 2>&1; then
  wget -qO "$INSTALL_PATH" "${REPO_RAW}/${SCRIPT_NAME}"
else
  error "curl or wget is required."
  exit 1
fi

chmod +x "$INSTALL_PATH"
info "Installed claude-bootstrap to ${INSTALL_PATH}"

# ── Shell integration ──────────────────────────────────────────
add_shell_alias() {
  local rc_file="$1"
  local alias_line="alias claude-bootstrap='${INSTALL_PATH}'"

  if [[ -f "$rc_file" ]] && grep -qF "claude-bootstrap" "$rc_file"; then
    warn "Shell alias already exists in ${rc_file} — skipped."
    return
  fi

  {
    printf "\n# claude-code-bootstrap\n"
    printf "%s\n" "$alias_line"
  } >> "$rc_file"

  info "Added alias to ${rc_file}"
}

# Detect shell — read from /dev/tty so the prompt works when piped (curl | bash)
printf "\n"
add_alias="Y"
if [[ -t 0 ]]; then
  # stdin is a terminal — read normally
  read -rp "Add claude-bootstrap alias to your shell config? [Y/n]: " add_alias
elif [[ -e /dev/tty ]]; then
  # stdin is piped (curl | bash) — read from tty directly
  read -rp "Add claude-bootstrap alias to your shell config? [Y/n]: " add_alias < /dev/tty
else
  # No terminal available (CI, etc.) — default to yes
  info "Non-interactive mode detected — adding shell alias automatically."
fi
add_alias="${add_alias:-Y}"

if [[ "${add_alias,,}" == "y" || "${add_alias,,}" == "yes" || -z "$add_alias" ]]; then
  added=false

  # Try zsh first, then bash
  if [[ -f "${HOME}/.zshrc" ]] || [[ "${SHELL:-}" == *"zsh"* ]]; then
    add_shell_alias "${HOME}/.zshrc"
    added=true
  fi

  if [[ -f "${HOME}/.bashrc" ]] || [[ "${SHELL:-}" == *"bash"* ]]; then
    add_shell_alias "${HOME}/.bashrc"
    added=true
  fi

  # Git Bash / MSYS2 on Windows
  if [[ "${OSTYPE:-}" == "msys" || "${OSTYPE:-}" == "mingw"* ]]; then
    if [[ -f "${HOME}/.bash_profile" ]]; then
      add_shell_alias "${HOME}/.bash_profile"
      added=true
    fi
  fi

  if [[ "$added" != "true" ]]; then
    warn "Could not detect shell config file."
    printf "  Add this manually to your shell config:\n\n"
    printf "    alias claude-bootstrap='%s'\n\n" "$INSTALL_PATH"
  fi
else
  printf "\n  You can run claude-bootstrap directly:\n"
  printf "    ${CYAN}%s${RESET}\n\n" "$INSTALL_PATH"
fi

# ── Done ───────────────────────────────────────────────────────
printf "\n${GREEN}Done!${RESET} Usage:\n\n"
printf "  ${CYAN}cd your-project${RESET}\n"
printf "  ${CYAN}claude-bootstrap${RESET}              # interactive profile picker\n"
printf "  ${CYAN}claude-bootstrap laravel${RESET}      # apply a profile directly\n"
printf "  ${CYAN}claude-bootstrap --help${RESET}       # see all options\n\n"

if [[ "${add_alias,,}" == "y" || "${add_alias,,}" == "yes" || -z "$add_alias" ]]; then
  printf "  Restart your shell or run: ${CYAN}source ~/.bashrc${RESET}\n\n"
fi
