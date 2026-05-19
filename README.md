<div align="center">

# Free Claude Code

An Anthropic-compatible proxy that lets Claude Code, the VS Code extension, JetBrains ACP, and chat bots route traffic through alternative model providers.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Python 3.14](https://img.shields.io/badge/python-3.14-3776ab.svg?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/downloads/)
[![uv](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/astral-sh/uv/main/assets/badge/v0.json&style=for-the-badge)](https://github.com/astral-sh/uv)
[![Tested with Pytest](https://img.shields.io/badge/testing-Pytest-00c0ff.svg?style=for-the-badge)](https://github.com/Pushpenderrathore/claude-code/actions/workflows/tests.yml)
[![Type checking: Ty](https://img.shields.io/badge/type%20checking-ty-ffcc00.svg?style=for-the-badge)](https://pypi.org/project/ty/)
[![Code style: Ruff](https://img.shields.io/badge/code%20formatting-ruff-f5a623.svg?style=for-the-badge)](https://github.com/astral-sh/ruff)
[![Logging: Loguru](https://img.shields.io/badge/logging-loguru-4ecdc4.svg?style=for-the-badge)](https://github.com/Delgan/loguru)

Free Claude Code forwards Anthropic Messages API traffic from Claude Code to a configurable set of upstream providers, including NVIDIA NIM, Kimi, Wafer, OpenRouter, DeepSeek, LM Studio, llama.cpp, Ollama, OpenCode Zen, and Z.ai. The client-side protocol that Claude Code expects remains stable, while the operator retains full control over which model — free, paid, or local — handles each request.

[Quick Start](#quick-start) · [Providers](#choose-a-provider) · [Clients](#connect-claude-code) · [Integrations](#optional-integrations) · [Development](#development)

</div>

<div align="center">
  <img src="assets/pic.png" alt="Free Claude Code in action" width="700">
</div>

## Overview

Free Claude Code provides:

- A drop-in proxy for the Anthropic API calls issued by Claude Code.
- Ten provider backends: NVIDIA NIM, Kimi, Wafer, OpenRouter, DeepSeek, LM Studio, llama.cpp, Ollama, OpenCode Zen, and Z.ai.
- Per-tier model routing, enabling Opus, Sonnet, Haiku, and fallback traffic to be directed to different providers.
- Native support for the Claude Code `/model` picker via the proxy's `/v1/models` endpoint. Claude Code must opt in to Gateway model discovery; see [Model Picker](#model-picker).
- Streaming, tool use, reasoning and thinking block handling, and local request optimizations.
- An optional Discord or Telegram bot wrapper for remote coding sessions.
- Optional usage through the VS Code extension.
- Optional voice-note transcription via local Whisper or NVIDIA NIM.
- A local administrative interface at `/admin` for editing supported proxy settings, validating changes, and verifying providers. Access is restricted to loopback.

## Quick Start

### 1. Install Claude Code

Install the latest release of [Claude Code](https://code.claude.com/docs/en/overview):

```bash
npm install -g @anthropic-ai/claude-code
```

### 2. Install Runtime Requirements

Install the latest version of [uv](https://docs.astral.sh/uv/getting-started/installation/) along with Python 3.14.

macOS and Linux:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
uv self update
uv python install 3.14
```

Windows PowerShell:

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
uv self update
uv python install 3.14
```

### 3. Obtain an NVIDIA NIM API Key

Create a free NVIDIA NIM API key and keep it available for the Admin UI configuration step. See [NVIDIA NIM provider setup](#nvidia-nim-provider) for details.

### 4. Install the Proxy

```bash
uv tool install --force git+https://github.com/Pushpenderrathore/claude-code.git
```

The same command is used to update an existing installation.

### 5. Start the Proxy

```bash
fcc-server
```

After startup, Uvicorn prints the proxy bind address and the application logs the administrative URL:

```text
INFO:     Admin UI: http://127.0.0.1:8082/admin (local-only)
```

Most terminals render this URL as a clickable link. Substitute the value of `PORT` if it differs from `8082`.

### 6. Open the Admin UI and Configure NVIDIA NIM

Open the Admin UI URL printed in the terminal.

<div align="center">
  <img src="assets/admin-page.png" alt="Local admin UI for proxy settings" width="700">
</div>

Paste the NVIDIA NIM API key into `NVIDIA_NIM_API_KEY`, click **Validate**, and then click **Apply**.

The default model is preset to `nvidia_nim/z-ai/glm4.7`. This may be changed at any time through the same Admin UI.

### 7. Launch Claude Code

```bash
fcc-claude
```

`fcc-claude` reads the currently configured port and authentication token on each invocation, sets the required Claude Code environment variables (including a 190,000-token `CLAUDE_CODE_AUTO_COMPACT_WINDOW` value for auto-compaction), and then launches the underlying `claude` command.

## Choose a Provider

Select a provider, supply its API key or local URL through the Admin UI, and set `MODEL` to a provider-prefixed model slug. `MODEL` acts as the fallback. The values `MODEL_OPUS`, `MODEL_SONNET`, and `MODEL_HAIKU` may be used to override routing for individual Claude Code model tiers.

<a id="nvidia-nim-provider"></a>

### 1. [NVIDIA NIM](https://build.nvidia.com/)

Obtain an API key at [build.nvidia.com/settings/api-keys](https://build.nvidia.com/settings/api-keys).

In the Admin UI, paste the key into `NVIDIA_NIM_API_KEY`. The default value of `MODEL` is `nvidia_nim/z-ai/glm4.7`.

Common examples:

- `nvidia_nim/z-ai/glm4.7`
- `nvidia_nim/z-ai/glm5`
- `nvidia_nim/moonshotai/kimi-k2.5`
- `nvidia_nim/minimaxai/minimax-m2.5`

Available models can be browsed at [build.nvidia.com](https://build.nvidia.com/explore/discover).

### 2. [Kimi](https://platform.moonshot.ai/)

Obtain an API key at [platform.moonshot.ai/console/api-keys](https://platform.moonshot.ai/console/api-keys).

In the Admin UI, paste the key into `KIMI_API_KEY` and set `MODEL` to a Kimi slug, such as `kimi/kimi-k2.5`.

Available models can be browsed at [platform.moonshot.ai](https://platform.moonshot.ai).

### 3. [Wafer](https://wafer.ai/)

Obtain an API key from [wafer.ai](https://wafer.ai). In the Admin UI, paste the key into `WAFER_API_KEY` and set `MODEL` to a Wafer Pass model, such as `wafer/DeepSeek-V4-Pro`.

Common examples:

- `wafer/DeepSeek-V4-Pro`
- `wafer/MiniMax-M2.7`
- `wafer/Qwen3.5-397B-A17B`
- `wafer/GLM-5.1`

This provider connects to Wafer's Anthropic-compatible endpoint at `https://pass.wafer.ai/v1/messages`.

### 4. [OpenRouter](https://openrouter.ai/)

Obtain an API key at [openrouter.ai/keys](https://openrouter.ai/keys).

In the Admin UI, paste the key into `OPENROUTER_API_KEY` and set `MODEL` to an OpenRouter slug, such as `open_router/stepfun/step-3.5-flash:free`.

Browse [all models](https://openrouter.ai/models) or the [free models](https://openrouter.ai/collections/free-models) collection.

### 5. [DeepSeek](https://platform.deepseek.com/)

Obtain an API key at [platform.deepseek.com/api_keys](https://platform.deepseek.com/api_keys).

In the Admin UI, paste the key into `DEEPSEEK_API_KEY` and set `MODEL` to a DeepSeek slug, such as `deepseek/deepseek-chat`.

This provider connects to DeepSeek's Anthropic-compatible endpoint rather than the OpenAI chat-completions endpoint.

### 6. [LM Studio](https://lmstudio.ai/)

Start the LM Studio local server and load a model. In the Admin UI, retain or update `LM_STUDIO_BASE_URL`, then set `MODEL` to the model identifier shown by LM Studio, prefixed with `lmstudio/`.

Models with tool-use support are preferred for Claude Code workflows.

### 7. [llama.cpp](https://github.com/ggml-org/llama.cpp)

Start `llama-server` with an Anthropic-compatible `/v1/messages` endpoint and sufficient context to handle Claude Code requests.

In the Admin UI, retain or update `LLAMACPP_BASE_URL`, then set `MODEL` to the local model slug, prefixed with `llamacpp/`.

Context size is significant for local coding models. If llama.cpp returns HTTP 400 for ordinary Claude Code requests, increase `--ctx-size` and confirm that the selected model and server build support the required features.

### 8. [Ollama](https://ollama.com/)

Run Ollama and pull a model:

```bash
ollama pull llama3.1
ollama serve
```

In the Admin UI, retain or update `OLLAMA_BASE_URL`, then set `MODEL` to the tag reported by `ollama list`, prefixed with `ollama/`.

`OLLAMA_BASE_URL` is the Ollama server root and should not include a `/v1` suffix. Examples of model slugs include `ollama/llama3.1` and `ollama/llama3.1:8b`.

### 9. [OpenCode Zen](https://opencode.ai/)

Obtain an API key at [opencode.ai/auth](https://opencode.ai/auth).

In the Admin UI, paste the key into `OPENCODE_API_KEY` and set `MODEL` to an OpenCode Zen model slug, such as `opencode/gpt-5.3-codex`.

OpenCode Zen is a curated model gateway that provides access to models from Anthropic, OpenAI, Google, DeepSeek, and others through a single API key and an OpenAI-compatible endpoint at `https://opencode.ai/zen/v1`.

Common examples:

- `opencode/gpt-5.3-codex`
- `opencode/claude-sonnet-4`
- `opencode/deepseek-v4-flash-free` (free)
- `opencode/gemini-3-flash`
- `opencode/big-pickle` (free)
- `opencode/glm-5.1`

Available models can be browsed at [opencode.ai](https://opencode.ai).

### 10. [Z.ai](https://z.ai/)

Obtain an API key at [Z.ai/manage-apikey/apikey-list](https://z.ai/manage-apikey/apikey-list).

In the Admin UI, paste the key into `ZAI_API_KEY` and set `MODEL` to a Z.ai model slug, such as `zai/glm-5.1`.

Z.ai exposes GLM models through the OpenAI-compatible Coding Plan endpoint at `https://api.z.ai/api/coding/paas/v4`.

Common examples:

- `zai/glm-5.1`
- `zai/glm-5-turbo`

Available models can be browsed at [Z.ai](https://z.ai).

### 11. Mixing Providers by Model Tier

Each model tier may use a distinct provider by configuring `MODEL_OPUS`, `MODEL_SONNET`, and `MODEL_HAIKU` in the Admin UI. Any tier left blank inherits the value of `MODEL`.

For example, Opus may be routed to `nvidia_nim/moonshotai/kimi-k2.5`, Sonnet to `open_router/deepseek/deepseek-r1-0528:free`, Haiku to `lmstudio/unsloth/GLM-4.7-Flash-GGUF`, while the fallback `MODEL` remains `zai/glm-5.1`.

## Connect Claude Code

### 1. Claude Code CLI

For terminal usage, the installed launcher is recommended:

```bash
fcc-claude
```

`fcc-server` must remain running during use. The Admin UI manages proxy configuration and restarts the server when runtime settings change. `fcc-claude` reads the current Admin UI-managed port and authentication token on each invocation and sets `CLAUDE_CODE_AUTO_COMPACT_WINDOW` to `190000` to enable auto-compaction.

### 2. VS Code Extension

Open Settings, search for `claude-code.environmentVariables`, choose **Edit in settings.json**, and add the following:

```json
"claudeCode.environmentVariables": [
  { "name": "ANTHROPIC_BASE_URL", "value": "http://localhost:8082" },
  { "name": "ANTHROPIC_AUTH_TOKEN", "value": "freecc" },
  { "name": "CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY", "value": "1" },
  { "name": "CLAUDE_CODE_AUTO_COMPACT_WINDOW", "value": "190000" }
]
```

Reload the extension. If the extension presents a login screen, complete the Anthropic Console path once; the local proxy will continue to handle model traffic after the environment variables take effect.

### 3. JetBrains ACP

Edit the installed Claude ACP configuration:

- Windows: `C:\Users\%USERNAME%\AppData\Roaming\JetBrains\acp-agents\installed.json`
- Linux and macOS: `~/.jetbrains/acp.json`

Set the environment block for `acp.registry.claude-acp`:

```json
"env": {
  "ANTHROPIC_BASE_URL": "http://localhost:8082",
  "ANTHROPIC_AUTH_TOKEN": "freecc",
  "CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY": "1",
  "CLAUDE_CODE_AUTO_COMPACT_WINDOW": "190000"
}
```

Restart the IDE after modifying the file.

### 4. Model Picker

<div align="center">
  <img src="assets/cc-model-picker.png" alt="Claude Code model picker showing gateway models" width="700">
</div>

## Optional Integrations

For all integrations described below, managed proxy settings should be modified exclusively through the Admin UI at `/admin`: edit the relevant fields, click **Validate**, and then click **Apply**. The footer indicates where the managed configuration is stored. Manual editing of that file is intentionally not documented here.

### 1. Discord and Telegram Bots

The bot wrapper executes Claude Code sessions remotely, streams progress, supports reply-based conversation branches, and provides controls for stopping or clearing tasks.

**Discord**

1. Create a bot in the [Discord Developer Portal](https://discord.com/developers/applications).
2. Enable the **Message Content Intent**.
3. Invite the bot with read, send, and message-history permissions.
4. Record the bot token and the numeric identifier of each channel in which the bot should respond.

**Telegram**

1. Create a bot through [@BotFather](https://t.me/BotFather) and record the bot token.
2. Retrieve the numeric user ID from [@userinfobot](https://t.me/userinfobot) so that access can be restricted to a single user.

**Admin UI Configuration**

1. With `fcc-server` running, open the Admin UI URL from the terminal output.
2. In the sidebar, select **Messaging**.
3. Set **Messaging Platform** to either **discord** or **telegram**.
4. For Discord, paste the **Discord Bot Token** and **Allowed Discord Channels**. For Telegram, paste the **Telegram Bot Token** and **Allowed Telegram User ID**.
5. Set **Allowed Directory** to an absolute path on the host running the proxy — the workspace root the bot is permitted to use.
6. Click **Validate**, then **Apply**. Restart the server if prompted.

<div align="center">
  <img src="assets/admin-messaging.png" alt="Admin UI Messaging view with bot and voice settings" width="700">
</div>

<p align="center"><em>Admin UI — Messaging view (platform, bots, and voice)</em></p>

**Commands**

- `/stop` cancels a task. Replying to a task message limits the cancellation to that branch.
- `/clear` resets sessions. Replying to a message limits the reset to that branch.
- `/stats` displays session state.

### 2. Voice Notes

Voice notes are supported on Discord and Telegram once the [proxy installation](#4-install-the-proxy) has been extended with the appropriate optional extras. Re-run `uv tool install --force` with the required extras (the Git URL matches the Quick Start):

```bash
# NVIDIA NIM transcription via Riva gRPC
uv tool install --force "claude-code[voice] @ git+https://github.com/Pushpenderrathore/claude-code.git"

# Local Whisper (CPU or CUDA)
uv tool install --force "claude-code[voice_local] @ git+https://github.com/Pushpenderrathore/claude-code.git"

# Both backends
uv tool install --force "claude-code[voice,voice_local] @ git+https://github.com/Pushpenderrathore/claude-code.git"
```

For CUDA-accelerated local Whisper, append `--torch-backend cu130` to the `voice_local` installation command. Restart `fcc-server` after each reinstallation.

In the Admin UI, open **Messaging** and scroll to **Voice**. Enable **Voice Notes**, choose a **Whisper Device** (`cpu`, `cuda`, or `nvidia_nim`), set a **Whisper Model**, and provide a **Hugging Face Token** if the configuration requires one. For **nvidia_nim** transcription, install the `voice` extra and set the **NVIDIA NIM API Key** on the **Providers** view. The screenshot above illustrates the **Voice** block within the same view.

## Architecture

<div align="center">
  <img src="assets/how-it-works.svg" alt="Free Claude Code request flow architecture" width="900">
</div>

Diagram source: [`assets/how-it-works.mmd`](assets/how-it-works.mmd).

Key components:

- FastAPI exposes Anthropic-compatible routes including `/v1/messages`, `/v1/messages/count_tokens`, and `/v1/models`.
- Model routing resolves the requested Claude model name to `MODEL_OPUS`, `MODEL_SONNET`, `MODEL_HAIKU`, or `MODEL`.
- NVIDIA NIM, OpenCode Zen, and Z.ai use OpenAI chat streaming, which is translated into Anthropic Server-Sent Events.
- Wafer, OpenRouter, DeepSeek, LM Studio, llama.cpp, and Ollama use Anthropic Messages-style transports.
- The proxy normalizes thinking blocks, tool calls, token usage metadata, and provider error responses into the shape expected by Claude Code.
- Request optimizations resolve trivial Claude Code probes locally to reduce latency and conserve quota.

## Development

### 1. Project Structure

```text
claude-code/
├── server.py              # ASGI entry point
├── api/                   # FastAPI routes, service layer, routing, optimizations
├── core/                  # Shared Anthropic protocol helpers and SSE utilities
├── providers/             # Provider transports, registry, rate limiting
├── messaging/             # Discord and Telegram adapters, sessions, voice
├── cli/                   # Package entry points and Claude process management
├── config/                # Settings, provider catalog, logging
└── tests/                 # Unit and contract tests
```

### 2. Running From Source

Use the following workflow when developing or running directly from a checkout:

```bash
git clone https://github.com/Pushpenderrathore/claude-code.git
cd claude-code
uv run uvicorn server:app --host 0.0.0.0 --port 8082
```

### 3. Standard Commands

```bash
uv run ruff format
uv run ruff check
uv run ty check
uv run pytest
```

These should be executed in the order shown prior to pushing. Continuous integration enforces the same sequence.

### 4. Package Scripts

`pyproject.toml` installs the following entry points:

- `fcc-server`: starts the proxy with the configured host and port.
- `fcc-init`: optional advanced scaffold for `~/.fcc/.env`. The Admin UI is preferred for routine configuration.
- `fcc-claude`: launches Claude Code with the configured local proxy URL, authentication token, model-discovery flag, and a 190,000-token `CLAUDE_CODE_AUTO_COMPACT_WINDOW` value for auto-compaction.
- `claude-code`: a compatibility alias for `fcc-server`.

### 5. Extending the Proxy

- Add OpenAI-compatible providers by extending `OpenAIChatTransport`.
- Add Anthropic Messages providers by extending `AnthropicMessagesTransport`.
- Register provider metadata in `config.provider_catalog` and factory wiring in `providers.registry`.
- Add messaging platforms by implementing the `MessagingPlatform` interface within `messaging/`.

## Contributing

- [`.env.example`](.env.example) enumerates environment key names as a read-only reference for contributors. Use the Admin UI to modify managed proxy settings.
- Bugs and feature requests should be reported through [Issues](https://github.com/Pushpenderrathore/claude-code/issues).
- Keep changes small and accompanied by focused tests.
- Docker integration pull requests will not be accepted.
- README change pull requests will not be accepted; open an issue instead.
- Run the full check sequence prior to opening a pull request.
- The `except X, Y` syntax is restored in the final release of Python 3.14 (not in the 3.14 alpha). This should be considered before opening pull requests.

## License

Released under the MIT License. See [LICENSE](LICENSE) for the full text.
