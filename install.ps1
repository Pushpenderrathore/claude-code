<#
.SYNOPSIS
    Free Claude Code — automated installer for Windows PowerShell.

.DESCRIPTION
    Installs and/or updates, in order:
      1. Node.js + npm     (via winget, falling back to Chocolatey) — if missing
      2. Claude Code CLI   (npm i -g @anthropic-ai/claude-code)
      3. astral uv         (irm https://astral.sh/uv/install.ps1 | iex)
      4. Python 3.14       (uv python install 3.14)
      5. The proxy itself  (uv tool install --force git+<repo>)

    Re-running is safe: each step is idempotent and self-updating.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\install.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'   # faster Invoke-WebRequest

$RepoUrl       = 'git+https://github.com/Pushpenderrathore/claude-code.git'
$PythonVersion = '3.14'

# ---------- pretty output ----------
function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Blue }
function Write-Ok  ($msg) { Write-Host "  + $msg"  -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  ! $msg"  -ForegroundColor Yellow }
function Write-Err ($msg) { Write-Host "  x $msg"  -ForegroundColor Red }

function Test-Command($name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Refresh-Path {
    # Pick up PATH changes made by installers in the current session.
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user    = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = ($machine, $user -join ';')
    # Ensure uv's default install dir is reachable even before a new shell.
    $uvBin = Join-Path $env:USERPROFILE '.local\bin'
    if ((Test-Path $uvBin) -and ($env:Path -notlike "*$uvBin*")) {
        $env:Path = "$uvBin;$env:Path"
    }
}

# ---------- 1. Node.js ----------
function Install-Node {
    if ((Test-Command node) -and (Test-Command npm)) {
        Write-Ok ("Node.js {0} and npm {1} already installed" -f (node -v), (npm -v))
        return
    }

    Write-Step 'Installing Node.js + npm'

    if (Test-Command winget) {
        # --silent + accept agreements so the script never prompts.
        winget install -e --id OpenJS.NodeJS.LTS --silent `
            --accept-source-agreements --accept-package-agreements
    }
    elseif (Test-Command choco) {
        choco install nodejs-lts -y
    }
    else {
        throw "Neither winget nor Chocolatey was found. Install Node.js LTS manually from https://nodejs.org/ and re-run this script."
    }

    Refresh-Path

    if (-not ((Test-Command node) -and (Test-Command npm))) {
        throw "Node.js installed but `node`/`npm` are not on PATH. Open a new PowerShell window and re-run the script."
    }
    Write-Ok ("Node.js {0}, npm {1}" -f (node -v), (npm -v))
}

# ---------- 2. Claude Code CLI ----------
function Install-ClaudeCli {
    Write-Step 'Installing/updating Claude Code CLI'
    # `--force` overwrites an existing `claude` shim on re-runs.
    npm install -g --force '@anthropic-ai/claude-code'
    Write-Ok 'Claude Code CLI installed'
}

# ---------- 3. uv ----------
function Install-Uv {
    if (Test-Command uv) {
        Write-Step ("uv already installed ({0}) - updating" -f (uv --version))
        try { uv self update } catch { Write-Warn 'uv self update returned non-zero (continuing)' }
    }
    else {
        Write-Step 'Installing uv'
        # Official Astral installer; honours $env:UV_INSTALL_DIR if set.
        Invoke-RestMethod -Uri 'https://astral.sh/uv/install.ps1' | Invoke-Expression
    }

    Refresh-Path
    if (-not (Test-Command uv)) {
        throw "uv installed but is not on PATH. Open a new PowerShell window and re-run the script."
    }
    Write-Ok ("uv {0}" -f (uv --version))
}

# ---------- 4. Python 3.14 ----------
function Install-Python {
    Write-Step "Installing Python $PythonVersion via uv"
    uv python install $PythonVersion
    Write-Ok "Python $PythonVersion ready"
}

# ---------- 5. proxy ----------
function Install-Proxy {
    Write-Step 'Installing Free Claude Code proxy'
    uv tool install --force $RepoUrl
    # Make sure uv's tool bin dir is on PATH for future shells.
    try { uv tool update-shell | Out-Null } catch { }
    Write-Ok 'Proxy installed (fcc-server, fcc-claude, fcc-init)'
}

# ---------- run ----------
try {
    Install-Node
    Install-ClaudeCli
    Install-Uv
    Install-Python
    Install-Proxy

    Write-Host ''
    Write-Host 'Installation complete.' -ForegroundColor Green
    Write-Host ''
    Write-Host 'Next steps:' -ForegroundColor White
    Write-Host '  # Open a new PowerShell window so PATH is fresh'
    Write-Host '  1. Start the proxy:           fcc-server'
    Write-Host '  2. Open the Admin UI link printed by the server (default http://127.0.0.1:8082/admin),'
    Write-Host '     paste your NVIDIA_NIM_API_KEY, click Validate then Apply.'
    Write-Host '  3. In another terminal, launch Claude Code through the proxy:'
    Write-Host '                                fcc-claude'
    Write-Host ''
}
catch {
    Write-Err ("Installation failed: {0}" -f $_.Exception.Message)
    exit 1
}
