# zsh-ai-helper

<div align="center">

![zsh-ai-logo](https://via.placeholder.com/150?text=zsh-ai)

**AI-powered ZSH plugin that instantly transforms natural language into shell commands**<br/>
Smart command-line assistant with enhanced safety features and error handling

[![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![ZSH](https://img.shields.io/badge/Shell-ZSH%205.0+-blue?style=flat-square)](https://www.zsh.org/)
[![Dependencies](https://img.shields.io/badge/Dependencies-zero-brightgreen?style=flat-square)](#)
[![Size](https://img.shields.io/badge/Size-~5KB-orange?style=flat-square)](#)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS-lightgrey?style=flat-square)](#)

[한국어](README.ko.md) • [Documentation](docs/)

</div>

---

## 📖 Project Overview

**zsh-ai-helper** is a lightweight plugin that leverages AI technology to convert natural language into ZSH shell commands.

### 💡 Why Do You Need This?

- **Problem:** Complex shell command syntax is hard to memorize, and searching every time is inefficient.
- **Solution:** Simply describe what you want in plain language, and AI instantly converts it into executable commands.

---

## 📸 Usage Examples

### Basic Usage

```bash
$ # Find all Python files modified in the last 7 days
$ find . -name "*.py" -mtime -7

$ # Find the 5 largest files in current directory
$ du -h . | sort -rh | head -5

$ # Kill process using port 3000
$ lsof -ti:3000 | xargs kill -9
```

### Command Explanation (`--e` flag)

```bash
$ # Find large files --e
$ find . -type f -size +100M  # Recursively searches for files larger than 100MB in the current directory

$ # List Docker containers --e
$ docker ps -a  # Displays all Docker containers, both running and stopped, with detailed information
```

### Automatic Dangerous Command Detection

```bash
$ # Delete all files
$ rm -rf /  # ⚠️  WARNING: This may delete ALL files on your system

$ # Format entire disk
$ mkfs.ext4 /dev/sda  # ⚠️  WARNING: Formatting will permanently erase all data on the disk
```

---

## ✨ Key Features

| Feature | Description |
|:---|:---|
| **Zero Dependencies** | Pure ZSH script (~5KB), only requires `curl` |
| **Multiple AI Providers** | Supports Anthropic Claude, OpenAI GPT, Google Gemini, Ollama (local) |
| **Context Aware** | Auto-detects project type, Git status, current directory |
| **Command Explanation** | Provides explanations for generated commands with `--e` flag |
| **Multilingual Support** | Supports 7 languages (EN, KO, JA, ZH, DE, FR, ES) |
| **Customizable** | YAML-based prompt configuration and custom prefix support |
| **Korean Documentation** | Full Korean README and guides available |

### 🛡️ Safety & Security

<details>
<summary><strong>⚠️ Automatic Dangerous Command Detection</strong></summary>

Automatically detects and warns about 20+ dangerous patterns:

- **File System Destruction**: `rm -rf /`, `dd if=/dev/zero`, `mkfs.*`
- **Permission Abuse**: `chmod 777`, `chmod -R 777`
- **System Shutdown**: `:(){ :|:& };:` (fork bomb), `shutdown`, `reboot`
- **Force Commands**: `--no-preserve-root`, `-f` flag combinations

Warning comments are automatically added when dangerous commands are detected.

</details>

<details>
<summary><strong>🔍 Improved Error Messages</strong></summary>

User-friendly detailed error guidance:

**cURL Error Handling**
- DNS resolution failure (error 6): Internet connection check guidance
- Connection refused (error 7): API server status check guidance
- Timeout (error 28): Timeout adjustment method
- SSL/TLS error (error 35): Certificate troubleshooting

**HTTP Status Code Guidance**
- 401 Unauthorized: API key verification method
- 429 Too Many Requests: Rate limit notice and wait recommendation
- 500 Internal Server Error: Server issue notice and retry recommendation

</details>

<details>
<summary><strong>🔒 Security Enhancements</strong></summary>

- **API Key Protection**: Prevents API key exposure in process list
- **File Permission Verification**: Auto-checks `.env` file permissions (600 or lower recommended)
- **Temporary File Security**: Protects API response temp files with 600 permissions

</details>

---

## 🚀 Installation

### Prerequisites

```bash
# Check ZSH version
zsh --version  # Requires 5.0 or higher

# Check curl installation
which curl

# Install jq (optional, for more reliable JSON parsing)
# Ubuntu/Debian
sudo apt install jq
# macOS
brew install jq
```

### Oh My Zsh Users (Recommended)

```bash
# 1. Clone to plugin directory
git clone https://github.com/Bae-ChangHyun/zsh-ai-helper ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai-helper

# 2. Edit ~/.zshrc
# Add zsh-ai-helper to plugins array
plugins=(... zsh-ai-helper)

# 3. Create config file
cp ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai-helper/.env.example \
   ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai-helper/.env

# 4. Configure API key in .env file (open with editor)
nano ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai-helper/.env

# 5. Restart ZSH
source ~/.zshrc
```

<details>
<summary><strong>Manual Installation</strong></summary>

If you're not using Oh My Zsh:

```bash
# 1. Clone to desired location
git clone https://github.com/Bae-ChangHyun/zsh-ai-helper ~/.zsh-ai-helper

# 2. Add the following line to ~/.zshrc
source ~/.zsh-ai-helper/zsh-ai.plugin.zsh

# 3. Create and edit config file
cp ~/.zsh-ai-helper/.env.example ~/.zsh-ai-helper/.env
nano ~/.zsh-ai-helper/.env

# 4. Restart ZSH
source ~/.zshrc
```

</details>

---

## 📖 Usage Guide

### Method 1: Comment Syntax (Recommended)

Type `#` followed by natural language description and press Enter:

```bash
$ # Find log files modified in last 24 hours
$ find /var/log -name "*.log" -mtime -1

$ # Show top 10 processes by CPU usage
$ ps aux --sort=-%cpu | head -11

$ # Undo last Git commit
$ git reset --soft HEAD~1
```

### Method 2: Direct Command

Use `zsh-ai` command directly:

```bash
$ zsh-ai "Delete all Docker images"
$ docker rmi $(docker images -q)

$ zsh-ai "Convert all .txt files to .md in current directory"
$ for file in *.txt; do mv "$file" "${file%.txt}.md"; done
```

### Method 3: Get Command Explanation

Add `--e` flag to get explanation as comment:

```bash
$ # Monitor network usage in real-time --e
$ nethogs  # Displays real-time network bandwidth usage per process

$ zsh-ai "Check system memory usage" --e
$ free -h  # Shows system memory usage in human-readable format
```

---

## ⚙️ Configuration Guide

### AI Provider Setup

Configure your AI provider and API key in `.env` file:

#### Supported Providers

| Provider | API Key Variable | Default Model | Cost | Features |
|:---:|:---:|:---:|:---:|:---|
| **Anthropic** | `ANTHROPIC_API_KEY` | `claude-haiku-4.5` | 💰 Paid | Fast and accurate, recommended |
| **OpenAI** | `OPENAI_API_KEY` | `gpt-4o` | 💰 Paid | Excellent versatility |
| **Gemini** | `GEMINI_API_KEY` | `gemini-2.5-flash` | 💰 Paid | Google's latest model |
| **Ollama** | (none) | `llama3.2` | 🆓 Free | Local execution, no internet required |

#### API Key Setup

<details>
<summary><strong>Anthropic Claude (Recommended)</strong></summary>

1. Visit [Anthropic Console](https://console.anthropic.com/)
2. Create new key in API Keys menu
3. Configure in `.env` file:

```bash
ZSH_AI_PROVIDER=anthropic
ANTHROPIC_API_KEY=sk-ant-api03-xxxxx
ANTHROPIC_MODEL=claude-haiku-4.5  # or claude-sonnet-4.5
```

</details>

<details>
<summary><strong>OpenAI GPT</strong></summary>

1. Visit [OpenAI Platform](https://platform.openai.com/api-keys)
2. Click "Create new secret key"
3. Configure in `.env` file:

```bash
ZSH_AI_PROVIDER=openai
OPENAI_API_KEY=sk-proj-xxxxx
OPENAI_MODEL=gpt-4o  # or gpt-4o-mini
```

</details>

<details>
<summary><strong>Google Gemini</strong></summary>

1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Generate API key
3. Configure in `.env` file:

```bash
ZSH_AI_PROVIDER=gemini
GEMINI_API_KEY=AIzaSyxxxxx
GEMINI_MODEL=gemini-2.5-flash
```

</details>

<details>
<summary><strong>Ollama (Local, Free)</strong></summary>

1. Install [Ollama](https://ollama.ai/)
2. Download model:

```bash
ollama pull llama3.2
# or other models
ollama pull codellama
```

3. Configure in `.env` file:

```bash
ZSH_AI_PROVIDER=ollama
OLLAMA_MODEL=llama3.2
OLLAMA_BASE_URL=http://localhost:11434  # default
```

</details>

### Advanced Configuration

#### Change Trigger Prefix (`ZSH_AI_PREFIX`)

Use different prefix instead of default `#`:

```bash
# .env file
ZSH_AI_PREFIX="? "    # Usage: ? find Python files
ZSH_AI_PREFIX="ai "   # Usage: ai find Python files
ZSH_AI_PREFIX=">> "   # Usage: >> system update
```

#### Change Explanation Language (`ZSH_AI_LANG`)

Set explanation language when using `--e` flag:

```bash
# .env file
ZSH_AI_LANG="KO"   # Korean (default: EN)
ZSH_AI_LANG="JA"   # Japanese
ZSH_AI_LANG="ZH"   # Chinese
```

#### Timeout Configuration (`ZSH_AI_TIMEOUT`)

API request timeout in seconds:

```bash
# .env file
ZSH_AI_TIMEOUT=60   # For slow networks
ZSH_AI_TIMEOUT=15   # For fast response needs
```

#### LLM Parameter Tuning (`ZSH_AI_EXTRA_KWARGS`)

Control model creativity, randomness, etc.:

```bash
# .env file
# More deterministic response (low temperature)
ZSH_AI_EXTRA_KWARGS='{"temperature": 0.1}'

# More creative response (high temperature)
ZSH_AI_EXTRA_KWARGS='{"temperature": 0.9, "top_p": 0.95}'
```

### Custom Prompt Configuration

Edit `prompt.yaml` file to fine-tune AI behavior:

```yaml
system_prompt: |
  You are a ZSH command generation expert.
  Convert user's natural language requests into accurate ZSH commands.

prompt_extend: |
  - Commands must be executable
  - Include warning comments for dangerous commands
  - Prioritize efficient and concise commands

explain_prompt: |
  Briefly explain the generated command in {lang} language.
  Write the explanation in one sentence, focusing on
  'what the command does' rather than technical details.
```

---

## 💻 Tech Stack

<div align="center">

![ZSH](https://img.shields.io/badge/Shell-ZSH-89e051?style=for-the-badge&logo=zsh&logoColor=white)
![cURL](https://img.shields.io/badge/HTTP-cURL-073551?style=for-the-badge&logo=curl&logoColor=white)
![Anthropic](https://img.shields.io/badge/AI-Anthropic%20Claude-181818?style=for-the-badge)
![OpenAI](https://img.shields.io/badge/AI-OpenAI%20GPT-412991?style=for-the-badge&logo=openai&logoColor=white)
![Gemini](https://img.shields.io/badge/AI-Google%20Gemini-4285F4?style=for-the-badge&logo=google&logoColor=white)

</div>

### Project Structure

```
zsh-ai-helper/
├── zsh-ai.plugin.zsh       # Plugin entry point
├── .env.example            # Configuration template
├── prompt.yaml             # AI prompt configuration
├── lib/
│   ├── config.zsh          # Configuration and .env loading
│   ├── context.zsh         # Context detection (git, project type, OS)
│   ├── utils.zsh           # Common utilities and main functions
│   ├── widget.zsh          # ZLE widget (# syntax)
│   ├── safety.zsh          # Dangerous command detection
│   └── providers/
│       ├── anthropic.zsh   # Anthropic Claude API
│       ├── openai.zsh      # OpenAI GPT API
│       ├── gemini.zsh      # Google Gemini API
│       └── ollama.zsh      # Ollama local API
└── docs/
    ├── README.ko.md        # Korean documentation
    └── ROADMAP.md          # Project roadmap
```

---

## 🤝 Contributing

If you'd like to contribute to project improvement:

1. Fork this repository
2. Create new branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Create Pull Request

For details, see [CONTRIBUTING.md](CONTRIBUTING.md).

---

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details.

Copyright (c) 2024-present Bae Chang Hyun

---

## 🙏 Acknowledgments

This project is based on [zsh-ai](https://github.com/matheusml/zsh-ai) by Matheus Lao. Thanks to the original author and contributors for the foundation.

---

<div align="center">

**Contact & Issue Reports**<br/>
[GitHub Issues](https://github.com/Bae-ChangHyun/zsh-ai-helper/issues)

Made with ❤️ by [Bae Chang Hyun](https://github.com/Bae-ChangHyun)<br/>
Based on [zsh-ai](https://github.com/matheusml/zsh-ai)

</div>
