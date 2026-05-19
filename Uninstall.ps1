<#
.SYNOPSIS
    Free Claude Code — automated uninstaller for Windows PowerShell.

.DESCRIPTION
    Removes, in order:
      1. The proxy itself    (uv tool uninstall claude-code)
      2. Claude Code CLI     (npm uninstall -g @anthropic-ai/claude-code) — only with -WithClaudeCli
      3. User config dir     (%USERPROFILE%\.fcc)                         — only with -Purge

    Re-running is safe: each step is idempotent and skips anything already gone.

    Intentionally leaves shared toolchain in place (Node.js, npm, uv, managed Pythons).
    Remove those manually if you want — this script will not touch them.

.PARAMETER WithClaudeCli
    Also npm-uninstall the @anthropic-ai/claude-code package globally.

.PARAMETER Purge
    Also delete %USERPROFILE%\.fcc (contains API keys, managed .env, logs).

.PARAMETER All
    Shorthand for -WithClaudeCli -Purge.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Uninstall.ps1

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Uninstall.ps1 -All
#>

[CmdletBinding()]
param(
    [switch]$WithClaudeCli,
    [switch]$Purge,
    [switch]$All
)

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

if ($All) {
    $WithClaudeCli = $true
    $Purge         = $true
}

$ToolName  = 'claude-code'
$NpmPkg    = '@anthropic-ai/claude-code'
$ConfigDir = Join-Path $env:USERPROFILE '.fcc'

# ---------- pretty output ----------
function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Blue }
function Write-Ok  ($msg) { Write-Host "  + $msg"  -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  ! $msg"  -ForegroundColor Yellow }
function Write-Err ($msg) { Write-Host "  x $msg"  -ForegroundColor Red }

function Test-Command($name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

# ---------- 1. proxy ----------
function Uninstall-Proxy {
    if (-not (Test-Command uv)) {
        Write-Warn 'uv not on PATH - skipping proxy uninstall (nothing this script can do)'
        return
    }

    Write-Step 'Uninstalling Free Claude Code proxy'
    $list = (& uv tool list 2>$null) -join "`n"
    if ($list -match "(?m)^$([regex]::Escape($ToolName))\s") {
        uv tool uninstall $ToolName
        Write-Ok 'Proxy removed (fcc-server, fcc-claude, fcc-init, claude-code)'
    }
    else {
        Write-Ok 'Proxy was not installed via uv tool - nothing to remove'
    }
}

# ---------- 2. Claude Code CLI ----------
function Uninstall-ClaudeCli {
    if (-not $WithClaudeCli) { return }

    Write-Step "Uninstalling Claude Code CLI ($NpmPkg)"
    if (-not (Test-Command npm)) {
        Write-Warn 'npm not found - skipping'
        return
    }

    & npm ls -g --depth=0 $NpmPkg 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Ok "$NpmPkg not installed globally - nothing to remove"
        return
    }

    npm uninstall -g $NpmPkg
    Write-Ok 'Claude Code CLI removed'
}

# ---------- 3. config dir ----------
function Remove-ConfigDir {
    if (-not $Purge) { return }

    Write-Step "Removing user config dir ($ConfigDir)"
    if (-not (Test-Path -LiteralPath $ConfigDir)) {
        Write-Ok "$ConfigDir does not exist - nothing to remove"
        return
    }

    Write-Warn "Deleting $ConfigDir (contains API keys, managed .env, logs)"
    Remove-Item -LiteralPath $ConfigDir -Recurse -Force
    Write-Ok 'Config dir removed'
}

# ---------- run ----------
try {
    Uninstall-Proxy
    Uninstall-ClaudeCli
    Remove-ConfigDir

    Write-Host ''
    Write-Host 'Uninstall complete.' -ForegroundColor Green
    Write-Host ''
    Write-Host 'Left in place (shared tooling - remove manually if you want them gone):' -ForegroundColor White
    Write-Host '  - Node.js + npm'
    Write-Host '  - astral uv      (uv self uninstall)'
    Write-Host '  - uv-managed Pythons (uv python uninstall <version>)'
    if (-not $Purge) {
        Write-Host "  - User config at $ConfigDir (re-run with -Purge to delete)"
    }
    if (-not $WithClaudeCli) {
        Write-Host "  - Claude Code CLI ($NpmPkg) (re-run with -WithClaudeCli to remove)"
    }
    Write-Host ''
}
catch {
    Write-Err ("Uninstall failed: {0}" -f $_.Exception.Message)
    exit 1
}
