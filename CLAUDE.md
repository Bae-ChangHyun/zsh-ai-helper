# Project Development Guide for zsh-ai

## Overview
Lightweight ZSH plugin for AI-powered command suggestions. Pure shell script with zero runtime dependencies.

## Project Structure
```
lib/
├── config.zsh      # Configuration and .env loading
├── context.zsh     # Context detection (git, project type, OS)
├── utils.zsh       # Shared utilities and main functions
├── widget.zsh      # ZLE widget for # syntax
└── providers/
    ├── openai.zsh
    ├── anthropic.zsh
    ├── gemini.zsh
    └── ollama.zsh
```

## Development

### Before Committing
1. Test manually with different providers
2. Ensure no API keys are committed

### Code Style
- Follow existing ZSH scripting patterns
- Use meaningful variable names with proper scoping
- Add error handling for external commands
- Keep functions small and focused

### Provider Implementation
When adding/modifying AI providers:
1. Implement in `lib/providers/`
2. Add timeout to curl calls (`--max-time "$ZSH_AI_TIMEOUT"`)
3. Use "Error:" prefix for all error messages
4. Update configuration documentation

### Important Notes
- Shell-only project - no Node.js, Python, etc.
- Keep codebase lightweight
- jq is optional (has fallback parsing)
- Test both `# query` syntax and `zsh-ai "query"` command
