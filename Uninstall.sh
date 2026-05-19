#!/usr/bin/env bash
# Free Claude Code — automated uninstaller
#
# Removes, in order:
#   1. The proxy itself     (uv tool uninstall claude-code)
#   2. Claude Code CLI      (npm uninstall -g @anthropic-ai/claude-code) — only with --with-claude-cli
#   3. User config dir      (~/.fcc/)                                    — only with --purge
#
# Re-running is safe: each step is idempotent and skips anything already gone.
#
# Intentionally leaves shared toolchain in place (Node.js, npm, uv, managed Pythons).
# Remove those manually if you want — this script will not touch them.
#
# Usage:
#   ./Uninstall.sh                     # remove the proxy only
#   ./Uninstall.sh --with-claude-cli   # also npm-uninstall the Claude Code CLI
#   ./Uninstall.sh --purge             # also delete ~/.fcc/ (contains API keys!)
#   ./Uninstall.sh --all               # both of the above

set -Eeuo pipefail

TOOL_NAME="claude-code"
NPM_PKG="@anthropic-ai/claude-code"
CONFIG_DIR="$HOME/.fcc"

WITH_CLI=0
PURGE=0

for arg in "$@"; do
    case "$arg" in
        --with-claude-cli) WITH_CLI=1 ;;
        --purge)           PURGE=1 ;;
        --all)             WITH_CLI=1; PURGE=1 ;;
        -h|--help)
            sed -n '2,20p' "$0"
            exit 0
            ;;
        *) printf 'Unknown option: %s\n' "$arg" >&2; exit 2 ;;
    esac
done

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

trap 'die "Uninstall failed at line $LINENO (last command: $BASH_COMMAND)"' ERR

have() { command -v "$1" >/dev/null 2>&1; }

# ---------- 1. proxy ----------
uninstall_proxy() {
    if ! have uv; then
        warn "uv not on PATH — skipping proxy uninstall (nothing this script can do)"
        return
    fi

    log "Uninstalling Free Claude Code proxy"
    if uv tool list 2>/dev/null | grep -q "^${TOOL_NAME} "; then
        uv tool uninstall "$TOOL_NAME"
        ok "Proxy removed (fcc-server, fcc-claude, fcc-init, claude-code)"
    else
        ok "Proxy was not installed via uv tool — nothing to remove"
    fi
}

# ---------- 2. claude code CLI ----------
uninstall_claude_cli() {
    [ "$WITH_CLI" -eq 1 ] || return

    log "Uninstalling Claude Code CLI ($NPM_PKG)"
    if ! have npm; then
        warn "npm not found — skipping"
        return
    fi

    if ! npm ls -g --depth=0 "$NPM_PKG" >/dev/null 2>&1; then
        ok "$NPM_PKG not installed globally — nothing to remove"
        return
    fi

    if npm uninstall -g "$NPM_PKG" 2>/tmp/fcc-npm-uninstall.log; then
        ok "Claude Code CLI removed"
    elif grep -q EACCES /tmp/fcc-npm-uninstall.log; then
        warn "Global npm uninstall lacks permission — retrying with sudo"
        sudo npm uninstall -g "$NPM_PKG"
        ok "Claude Code CLI removed (with sudo)"
    else
        cat /tmp/fcc-npm-uninstall.log >&2
        die "npm uninstall of $NPM_PKG failed"
    fi
}

# ---------- 3. config dir ----------
purge_config() {
    [ "$PURGE" -eq 1 ] || return

    log "Removing user config dir ($CONFIG_DIR)"
    if [ ! -e "$CONFIG_DIR" ]; then
        ok "$CONFIG_DIR does not exist — nothing to remove"
        return
    fi

    warn "Deleting $CONFIG_DIR (contains API keys, managed .env, logs)"
    rm -rf -- "$CONFIG_DIR"
    ok "Config dir removed"
}

# ---------- run ----------
uninstall_proxy
uninstall_claude_cli
purge_config

cat <<EOF

${GREEN}${BOLD}Uninstall complete.${RESET}

${BOLD}Left in place${RESET} (shared tooling — remove manually if you want them gone):
  ${DIM}- Node.js + npm${RESET}
  ${DIM}- astral uv      (uv self uninstall)${RESET}
  ${DIM}- uv-managed Pythons (uv python uninstall <version>)${RESET}
EOF

if [ "$PURGE" -ne 1 ]; then
    cat <<EOF
  ${DIM}- User config at $CONFIG_DIR (re-run with --purge to delete)${RESET}
EOF
fi

if [ "$WITH_CLI" -ne 1 ]; then
    cat <<EOF
  ${DIM}- Claude Code CLI ($NPM_PKG) (re-run with --with-claude-cli to remove)${RESET}
EOF
fi

printf '\n'
