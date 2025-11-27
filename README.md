# zsh-ai

> Transform natural language into shell commands instantly

<img src="https://img.shields.io/github/v/release/matheusml/zsh-ai?label=version&color=yellow" alt="Version"> <img src="https://img.shields.io/badge/dependencies-zero-brightgreen" alt="Zero Dependencies"> <img src="https://img.shields.io/badge/size-<5KB-blue" alt="Tiny Size"> <img src="https://img.shields.io/github/license/matheusml/zsh-ai?color=lightgrey" alt="License">

A lightweight ZSH plugin that converts natural language to shell commands using AI. Supports Anthropic Claude, OpenAI, Google Gemini, and local Ollama models.

## Features

- **Zero Dependencies** - Pure shell script (~5KB), only requires `curl`
- **Multiple Providers** - Anthropic, OpenAI, Gemini, Ollama (local)
- **Context Aware** - Detects project type, git status, current directory
- **Command Explanation** - `--e` flag explains generated commands
- **Multi-language Support** - Explanations in EN, KO, JA, ZH, DE, FR, ES
- **Customizable** - Custom prefix, prompts via YAML configuration

## Installation

### Prerequisites

- zsh 5.0+
- `curl`
- `jq` (optional, for better reliability)

### Oh My Zsh

```bash
# 1. Clone
git clone https://github.com/matheusml/zsh-ai ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai

# 2. Add to ~/.zshrc
plugins=(... zsh-ai)

# 3. Configure
cp ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai/.env.example \
   ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai/.env

# 4. Edit .env with your provider and API key

# 5. Reload
source ~/.zshrc
```

## Usage

### Comment Syntax (Recommended)

Type `#` followed by your request and press Enter:

<img src="https://github.com/user-attachments/assets/eff46629-855c-41eb-9de3-a53040bd2654" alt="Method 1 Demo" width="480">

```bash
$ # find large files modified this week
$ find . -type f -size +50M -mtime -7

$ # kill process using port 3000
$ lsof -ti:3000 | xargs kill -9
```

### Direct Command

Use `zsh-ai` command directly:

<img src="https://github.com/user-attachments/assets/e58f0b99-68bf-45a5-87b9-ba7f925ddc87" alt="Method 2 Demo" width="480">

```bash
$ zsh-ai "find large files modified this week"
$ find . -type f -size +50M -mtime -7
```

### Command Explanation (--e)

Add `--e` to get an inline explanation:

```bash
$ # find large files --e
$ find . -type f -size +100M  # Finds files larger than 100MB recursively

$ zsh-ai "list docker containers" --e
$ docker ps  # Lists all running Docker containers with details
```

## Configuration

All settings are in `.env` file. See `.env.example` for all available options.

### Providers

| Provider | API Key Variable | Default Model |
|----------|-----------------|---------------|
| Anthropic (default) | `ANTHROPIC_API_KEY` | claude-haiku-4-5 |
| OpenAI | `OPENAI_API_KEY` | gpt-4o |
| Gemini | `GEMINI_API_KEY` | gemini-2.5-flash |
| Ollama | - (local) | llama3.2 |

### Options

#### `ZSH_AI_PREFIX`
Change the trigger prefix (default: `# `):
```bash
ZSH_AI_PREFIX="? "    # Use: ? find python files
ZSH_AI_PREFIX="ai "   # Use: ai find python files
```

#### `ZSH_AI_LANG`
Set explanation language for `--e` flag (default: `EN`):
```bash
ZSH_AI_LANG="KO"   # Korean
ZSH_AI_LANG="JA"   # Japanese
ZSH_AI_LANG="ZH"   # Chinese
```

#### `ZSH_AI_TIMEOUT`
API request timeout in seconds (default: `30`):
```bash
ZSH_AI_TIMEOUT=60   # Increase for slow connections
```

#### `ZSH_AI_EXTRA_KWARGS`
Override LLM parameters in JSON format:
```bash
ZSH_AI_EXTRA_KWARGS='{"temperature": 0.1}'
ZSH_AI_EXTRA_KWARGS='{"temperature": 0.5, "top_p": 0.9}'
```

### Custom Prompts

Edit `prompt.yaml` to customize AI behavior:

```yaml
system_prompt: |
  Your custom system prompt...

prompt_extend: |
  Additional instructions...

explain_prompt: |
  Custom explanation prompt for --e flag...
```

## Project Structure

```
zsh-ai/
├── zsh-ai.plugin.zsh    # Entry point
├── .env.example         # Configuration template
├── prompt.yaml          # Prompt configuration
├── lib/
│   ├── config.zsh       # Configuration loader
│   ├── context.zsh      # Context detection
│   ├── utils.zsh        # Core utilities
│   ├── widget.zsh       # ZLE widget
│   └── providers/
│       ├── anthropic.zsh
│       ├── openai.zsh
│       ├── gemini.zsh
│       └── ollama.zsh
└── docs/
    ├── README.ko.md     # Korean documentation
    └── INSTALL.ko.md
```

## Documentation

- [Contributing](CONTRIBUTING.md)

### Korean (한국어)
- [README 한국어](docs/README.ko.md)
- [설치 가이드](docs/INSTALL.ko.md)

## License

MIT
