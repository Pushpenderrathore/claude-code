#!/usr/bin/env bash
# Free Claude Code — automated installer
#
# Installs and/or updates:
#   1. Node.js + npm (via Homebrew on macOS, apt/dnf/pacman on Linux) — if missing
#   2. Claude Code CLI    (npm i -g @anthropic-ai/claude-code)
#   3. astral uv          (curl -LsSf https://astral.sh/uv/install.sh | sh)
#   4. Python 3.14        (uv python install 3.14)
#   5. The proxy itself   (uv tool install --force git+<repo>)
#
# Re-running is safe: each step is idempotent and self-updating.

set -Eeuo pipefail

REPO_URL="git+https://github.com/Pushpenderrathore/claude-code.git"
PYTHON_VERSION="3.14"

# ---------- pretty output ----------
if [ -t 1 ]; then
    BOLD=$(printf '\033[1m'); DIM=$(printf '\033[2m')
    RED=$(printf '\033[31m'); GREEN=$(printf '\033[32m')
    YELLOW=$(printf '\033[33m'); BLUE=$(printf '\033[34m')
    RESET=$(printf '\033[0m')
else
    BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; RESET=""
fi

log()  { printf '%s==>%s %s%s%s\n' "$BLUE"   "$RESET" "$BOLD" "$*" "$RESET"; }
ok()   { printf '%s  ✓%s %s\n'    "$GREEN"  "$RESET" "$*"; }
warn() { printf '%s  ! %s%s\n'    "$YELLOW" "$*"     "$RESET"; }
die()  { printf '%s  ✗ %s%s\n'    "$RED"    "$*"     "$RESET" >&2; exit 1; }

trap 'die "Installation failed at line $LINENO (last command: $BASH_COMMAND)"' ERR

have() { command -v "$1" >/dev/null 2>&1; }

# ---------- platform detection ----------
detect_os() {
    case "$(uname -s)" in
        Darwin*) echo "macos"  ;;
        Linux*)  echo "linux"  ;;
        *)       echo "other"  ;;
    esac
}

OS="$(detect_os)"
log "Detected platform: $OS"

# ---------- 1. node + npm ----------
install_node() {
    if have npm && have node; then
        ok "Node.js $(node -v) and npm $(npm -v) already installed"
        return
    fi

    log "Installing Node.js + npm"
    case "$OS" in
        macos)
            if ! have brew; then
                die "Homebrew not found. Install it from https://brew.sh and re-run, or install Node.js manually."
            fi
            brew install node
            ;;
        linux)
            if   have apt-get; then sudo apt-get update -y && sudo apt-get install -y nodejs npm
            elif have dnf;     then sudo dnf install -y nodejs npm
            elif have pacman;  then sudo pacman -Sy --noconfirm nodejs npm
            elif have zypper;  then sudo zypper install -y nodejs npm
            else die "No supported package manager (apt/dnf/pacman/zypper) found. Install Node.js manually." ; fi
            ;;
        *)
            die "Unsupported OS for automatic Node.js install. Install Node.js manually and re-run."
            ;;
    esac
    ok "Node.js $(node -v), npm $(npm -v)"
}

# ---------- 2. claude code CLI ----------
install_claude_cli() {
    log "Installing/updating Claude Code CLI"
    # `--force` lets us overwrite an existing `claude` binary on re-runs.
    if npm install -g --force @anthropic-ai/claude-code 2>/tmp/fcc-npm.log; then
        ok "Claude Code CLI installed"
    elif grep -q EACCES /tmp/fcc-npm.log; then
        warn "Global npm install lacks permission — retrying with sudo"
        sudo npm install -g --force @anthropic-ai/claude-code
        ok "Claude Code CLI installed (with sudo)"
    else
        cat /tmp/fcc-npm.log >&2
        die "npm install of @anthropic-ai/claude-code failed"
    fi
}

# ---------- 3. uv ----------
install_uv() {
    if have uv; then
        log "uv already installed ($(uv --version)) — updating"
        uv self update || warn "uv self update returned non-zero (continuing)"
    else
        log "Installing uv"
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi

    # Ensure uv is on PATH for the remainder of this script and future shells.
    if [ -f "$HOME/.local/bin/env" ]; then
        # shellcheck disable=SC1091
        . "$HOME/.local/bin/env"
    fi
    case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) export PATH="$HOME/.local/bin:$PATH" ;;
    esac

    have uv || die "uv installed but not on PATH. Open a new shell and re-run."
    ok "uv $(uv --version)"

    # Persist PATH for future shells (idempotent).
    persist_uv_path
}

persist_uv_path() {
    local line='source $HOME/.local/bin/env'
    local rc=""

    case "${SHELL:-}" in
        */zsh)  rc="$HOME/.zshrc"  ;;
        */bash) rc="$HOME/.bashrc" ;;
        */fish)
            local frc="$HOME/.config/fish/config.fish"
            local fline='source $HOME/.local/bin/env.fish'
            mkdir -p "$(dirname "$frc")"
            touch "$frc"
            grep -qsF "$fline" "$frc" || printf '\n# uv\n%s\n' "$fline" >> "$frc"
            return
            ;;
        *) return ;;
    esac

    [ -n "$rc" ] || return
    touch "$rc"
    grep -qsF "$line" "$rc" || printf '\n# uv\n%s\n' "$line" >> "$rc"
}

# ---------- 4. python 3.14 ----------
install_python() {
    log "Installing Python $PYTHON_VERSION via uv"
    uv python install "$PYTHON_VERSION"
    ok "Python $PYTHON_VERSION ready"
}

# ---------- 5. proxy ----------
install_proxy() {
    log "Installing Free Claude Code proxy"
    uv tool install --force "$REPO_URL"
    ok "Proxy installed (fcc-server, fcc-claude, fcc-init)"

    # uv tool bins live in ~/.local/bin which we already added above.
    uv tool update-shell >/dev/null 2>&1 || true
}

# ---------- run ----------
install_node
install_claude_cli
install_uv
install_python
install_proxy

cat <<EOF

${GREEN}${BOLD}Installation complete.${RESET}

${BOLD}Next steps:${RESET}
  ${DIM}# Open a new shell (or run: source \$HOME/.local/bin/env) so PATH is fresh${RESET}
  1. Start the proxy:        ${BOLD}fcc-server${RESET}
  2. Open the Admin UI link printed by the server (default http://127.0.0.1:8082/admin),
     paste your NVIDIA_NIM_API_KEY, click ${BOLD}Validate${RESET} then ${BOLD}Apply${RESET}.
  3. In another terminal, launch Claude Code through the proxy:
                              ${BOLD}fcc-claude${RESET}

EOF
