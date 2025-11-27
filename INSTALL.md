# Installation Guide

## Prerequisites

- zsh 5.0+ (you probably already have this)
- `curl` (already on macOS/Linux)
- `jq` (optional, for better reliability)

**Choose your AI provider:**
- **Anthropic Claude** (default): [Get API key](https://console.anthropic.com/account/keys)
- **Google Gemini**: [Get API key](https://makersuite.google.com/app/apikey)
- **OpenAI**: [Get API key](https://platform.openai.com/api-keys)
- **Ollama** (local): [Install Ollama](https://ollama.ai/download)

## Installation

### Homebrew (Recommended)

1. Run this

```bash
brew tap matheusml/zsh-ai
brew install zsh-ai
```

2. Add this to your `~/.zshrc`

```bash
source $(brew --prefix)/share/zsh-ai/zsh-ai.plugin.zsh
```

3. Start a new terminal session.

### Antigen

1. Add the following to your `.zshrc`:

    ```sh
    antigen bundle matheusml/zsh-ai
    ```

2. Start a new terminal session.

### Oh My Zsh

1. Clone it
```bash
git clone https://github.com/matheusml/zsh-ai ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai
```

2. Add `zsh-ai` to your plugins list in `~/.zshrc`:

```bash
plugins=(
    # other plugins...
    zsh-ai
)
```

3. Start a new terminal session.

### Manual Installation

1. Clone it
```bash
git clone https://github.com/matheusml/zsh-ai ~/.zsh-ai
```

2. Add it to your `~/.zshrc`
```bash
echo "source ~/.zsh-ai/zsh-ai.plugin.zsh" >> ~/.zshrc
```

3. Start a new terminal session.

## Setup

Configure zsh-ai using a `.env` file:

1. Copy the example file:
```bash
# For Oh My Zsh installation
cp ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai/.env.example ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai/.env

# For manual installation
cp ~/.zsh-ai/.env.example ~/.zsh-ai/.env
```

2. Edit the `.env` file with your settings:
```bash
# Example for Anthropic (default)
ZSH_AI_PROVIDER="anthropic"
ANTHROPIC_API_KEY="your-api-key-here"

# Example for OpenAI
ZSH_AI_PROVIDER="openai"
OPENAI_API_KEY="your-api-key-here"

# Example for Gemini
ZSH_AI_PROVIDER="gemini"
GEMINI_API_KEY="your-api-key-here"

# Example for Ollama (local, no API key needed)
ZSH_AI_PROVIDER="ollama"

# Example for Perplexity (uses OpenAI-compatible API)
ZSH_AI_PROVIDER="openai"
OPENAI_API_KEY="pplx-your-api-key"
ZSH_AI_OPENAI_URL="https://api.perplexity.ai/chat/completions"
ZSH_AI_OPENAI_MODEL="llama-3.1-sonar-small-128k-online"
```

The plugin automatically loads `.env` from:
- Plugin directory (priority)
- `~/.zsh-ai.env` (alternative location)

**Note:** You only need to set the API key for your chosen provider.

## Configuration

All configuration is managed via `.env` file:

```bash
# =============================================================================
# Provider Selection
# =============================================================================
# Options: "anthropic" (default), "gemini", "openai", "ollama"
ZSH_AI_PROVIDER="anthropic"

# =============================================================================
# API Keys (only set for your chosen provider)
# =============================================================================
ANTHROPIC_API_KEY="your-key"
OPENAI_API_KEY="your-key"
GEMINI_API_KEY="your-key"

# =============================================================================
# Provider-specific settings
# =============================================================================

# Anthropic
ZSH_AI_ANTHROPIC_MODEL="claude-haiku-4-5"

# OpenAI
ZSH_AI_OPENAI_MODEL="gpt-4o"
ZSH_AI_OPENAI_URL="https://api.openai.com/v1/chat/completions"

# Gemini
ZSH_AI_GEMINI_MODEL="gemini-2.5-flash"

# Ollama
ZSH_AI_OLLAMA_MODEL="llama3.2"
ZSH_AI_OLLAMA_URL="http://localhost:11434"

# =============================================================================
# Advanced settings
# =============================================================================

# Request timeout (seconds)
ZSH_AI_TIMEOUT=30

# Extra kwargs for LLM API calls (JSON format)
ZSH_AI_EXTRA_KWARGS='{"temperature": 0.1}'
```

**That's it!** Most users only need to set `ZSH_AI_PROVIDER` and the corresponding API key.

## Customizing the Prompt

The AI prompt can be customized by editing `prompt.yaml` in the plugin directory:

```yaml
system_prompt: |
  You are a zsh command generator...

  Your custom instructions here.

# Optional: Add extra instructions without replacing the main prompt
prompt_extend: |
  Always prefer modern CLI tools like ripgrep, fd, and bat.
```

Alternatively, set `ZSH_AI_PROMPT_EXTEND` in your `.env` file for simple extensions:

```bash
ZSH_AI_PROMPT_EXTEND="Always prefer ripgrep (rg) over grep, fd over find."
```
