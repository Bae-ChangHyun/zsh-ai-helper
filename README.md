# zsh-ai

> The lightweight AI assistant that lives in your terminal

Transform natural language into shell commands instantly. Works with cloud-based AI (Anthropic Claude, Google Gemini, OpenAI) and local models (Ollama). No dependencies, no complex setup - just type what you want and get the command you need.

<img src="https://img.shields.io/github/v/release/matheusml/zsh-ai?label=version&color=yellow" alt="Version"> <img src="https://img.shields.io/badge/dependencies-zero-brightgreen" alt="Zero Dependencies"> <img src="https://img.shields.io/badge/size-<5KB-blue" alt="Tiny Size"> <img src="https://img.shields.io/github/license/matheusml/zsh-ai?color=lightgrey" alt="License">

## Why zsh-ai?

**Featherweight** - A single 5KB shell script. No Python, no Node.js, etc.

**Lightning Fast** - Starts instantly with your shell.

**Dead Simple** - Just type `# what you want to do` and press Enter. That's it.

**Privacy First** - Use local Ollama models for complete privacy, or bring your own API keys. Your commands stay local, API calls only when you trigger them.

**Zero Dependencies** - Optionally `jq` for reliability.

**Context Aware** - Automatically detects project type, git status, and current directory for smarter suggestions.

## Demo

### Method 1: Comment Syntax (Recommended)
Type `#` followed by what you want to do, then press Enter. It's that simple!

<img src="https://github.com/user-attachments/assets/eff46629-855c-41eb-9de3-a53040bd2654" alt="Method 1 Demo" width="480">


```bash
$ # find all large files modified this week
$ find . -type f -size +50M -mtime -7

$ # kill process using port 3000
$ lsof -ti:3000 | xargs kill -9

$ # compress images in current directory
$ for img in *.{jpg,png}; do convert "$img" -quality 85 "$img"; done
```

---

### Method 2: Direct Command
Prefer explicit commands? Use `zsh-ai` followed by your natural language request.

<img src="https://github.com/user-attachments/assets/e58f0b99-68bf-45a5-87b9-ba7f925ddc87" alt="Method 2 Demo" width="480">


```bash
$ zsh-ai "find all large files modified this week"
$ find . -type f -size +50M -mtime -7

$ zsh-ai "kill process using port 3000"
$ lsof -ti:3000 | xargs kill -9

$ zsh-ai "compress images in current directory"
$ for img in *.{jpg,png}; do convert "$img" -quality 85 "$img"; done
```

---

### Command Explanation (--e flag)
Add `--e` at the end of your query to get an inline explanation comment with the generated command.

```bash
$ # find large files --e
$ find . -type f -size +100M  # Finds files larger than 100MB recursively

$ zsh-ai "list all running docker containers" --e
$ docker ps  # Lists all running Docker containers with details
```

This makes a second API call to explain what the command does - useful for learning or documenting scripts. The explanation appears as an inline comment that is ignored when executed.

## Quick Start

### 1. Install (Oh My Zsh)

```bash
git clone https://github.com/matheusml/zsh-ai ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai
```

Add to your `~/.zshrc`:
```bash
plugins=(
    # other plugins...
    zsh-ai
)
```

### 2. Configure

```bash
# Copy the example config
cp ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai/.env.example \
   ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-ai/.env

# Edit .env with your settings
# ZSH_AI_PROVIDER="openai"
# OPENAI_API_KEY="your-api-key"
```

### 3. Reload & Use

```bash
source ~/.zshrc
```

Type `# your command` and press Enter!

**[Full Installation Guide](INSTALL.md)**


## Configuration

### Custom Prefix

Don't like `#`? Change it in your `.env` file:

```bash
# Use "? " as prefix
ZSH_AI_PREFIX="? "
# Now type: ? find all python files

# Use "ai " as prefix
ZSH_AI_PREFIX="ai "
# Now type: ai find all python files

# Use ">> " as prefix
ZSH_AI_PREFIX=">> "
# Now type: >> find all python files
```

### Custom Prompt

Edit `prompt.yaml` in the plugin directory to customize AI behavior:

```yaml
system_prompt: |
  Your custom prompt here...

prompt_extend: |
  Additional instructions...
```

**[Full Configuration Guide](INSTALL.md#configuration-options)**


## Documentation

- **[Installation & Setup](INSTALL.md)** - Detailed installation instructions
- **[Configuration](INSTALL.md#configuration-options)** - API keys, providers, and customization options
- **[Contributing](CONTRIBUTING.md)** - Help make zsh-ai better!

### 한국어 문서 (Korean)
- **[README 한국어](docs/README.ko.md)**
- **[설치 가이드](docs/INSTALL.ko.md)**
