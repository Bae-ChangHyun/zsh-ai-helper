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

### Oh My Zsh

1. Clone repo
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

```bash
source ~/.zshrc
```

## Setup

Configure zsh-ai using a `.env` file:

1. Copy the example file:
```bash
cp ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai/.env.example ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai/.env
```

2. Edit the `.env` file with your settings:

The plugin automatically loads `.env` from:
- Plugin directory (priority)
- `~/.zsh-ai.env` (alternative location)

**Note:** You need to set the API key for your chosen provider.


## Usage Options

### Command Explanation (--e flag)

Add `--e` at the end of your query to get an explanation comment above the generated command:

```bash
# Using comment syntax
$ # find large files --e
$ # Finds files larger than 100MB in the current directory recursively
$ find . -type f -size +100M

# Using direct command
$ zsh-ai "compress all images" --e
$ # Compresses all jpg and png images in current directory to 85% quality
$ for img in *.{jpg,png}; do convert "$img" -quality 85 "$img"; done
```

This makes a second API call to explain the command - useful for learning or documenting scripts.

## Configuration Options

All settings in `.env` file:

```bash
# Provider: "anthropic" (default), "gemini", "openai", "ollama"
ZSH_AI_PROVIDER="openai"

# API Keys (only set for your chosen provider)
OPENAI_API_KEY="your-key"
ANTHROPIC_API_KEY="your-key"
GEMINI_API_KEY="your-key"

# Provider-specific models
ZSH_AI_OPENAI_MODEL="gpt-4o"
ZSH_AI_ANTHROPIC_MODEL="claude-haiku-4-5"
ZSH_AI_GEMINI_MODEL="gemini-2.5-flash"
ZSH_AI_OLLAMA_MODEL="llama3.2"

# Custom API endpoints
ZSH_AI_OPENAI_URL="https://api.openai.com/v1/chat/completions"
ZSH_AI_OLLAMA_URL="http://localhost:11434"

# Command prefix to trigger AI (default: "# ")
# Examples: "? ", "ai ", ">> "
ZSH_AI_PREFIX="# "

# Request timeout in seconds (default: 30)
ZSH_AI_TIMEOUT=30

# Extra kwargs for LLM API calls (JSON format)
ZSH_AI_EXTRA_KWARGS='{"temperature": 0.1}'
```


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
