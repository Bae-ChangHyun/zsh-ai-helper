#!/usr/bin/env zsh

# Configuration and validation for zsh-ai

# Load .env file if it exists
# Searches in: plugin directory, home directory
_zsh_ai_load_env() {
    local env_file=""
    # Try to find plugin directory - use ZSH_AI_PLUGIN_DIR if set, otherwise derive from script path
    local plugin_dir="${ZSH_AI_PLUGIN_DIR:-${0:A:h:h}}"

    # Priority: plugin directory > home directory
    if [[ -f "${plugin_dir}/.env" ]]; then
        env_file="${plugin_dir}/.env"
    elif [[ -f "${HOME}/.zsh-ai.env" ]]; then
        env_file="${HOME}/.zsh-ai.env"
    fi

    if [[ -n "$env_file" ]]; then
        # Read and export each line from .env file
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            # Skip lines without =
            [[ "$line" != *"="* ]] && continue
            # Extract key and value
            local key="${line%%=*}"
            local value="${line#*=}"
            # Remove leading/trailing whitespace from key
            key="${key##[[:space:]]}"
            key="${key%%[[:space:]]}"
            # Remove surrounding quotes from value if present
            value="${value##[[:space:]]}"
            value="${value%%[[:space:]]}"
            value="${value#\"}"
            value="${value%\"}"
            value="${value#\'}"
            value="${value%\'}"
            # Always set from .env file (overrides any existing value)
            export "$key=$value"
        done < "$env_file"
    fi
}

# Load .env file first
_zsh_ai_load_env

# Set default values for configuration
: ${ZSH_AI_PROVIDER:="anthropic"}  # Default to anthropic for backwards compatibility
: ${ZSH_AI_OLLAMA_MODEL:="llama3.2"}  # Popular fast model
: ${ZSH_AI_OLLAMA_URL:="http://localhost:11434"}  # Default Ollama URL
: ${ZSH_AI_GEMINI_MODEL:="gemini-2.5-flash"}  # Fast Gemini 2.5 model
: ${ZSH_AI_OPENAI_MODEL:="gpt-4o"}  # Default to GPT-4o
: ${ZSH_AI_OPENAI_URL:="https://api.openai.com/v1/chat/completions"}  # Default to OpenAI
: ${ZSH_AI_ANTHROPIC_MODEL:="claude-haiku-4-5"}  # Default Anthropic model

# Optional: Extend the system prompt with custom instructions
# ZSH_AI_PROMPT_EXTEND - Add custom instructions to the AI prompt without replacing the core prompt
# Example: export ZSH_AI_PROMPT_EXTEND="Always prefer ripgrep (rg) over grep. Use modern CLI tools when available."

# Optional: Extra kwargs for LLM API calls (JSON format)
# ZSH_AI_EXTRA_KWARGS - Add extra parameters to API calls
# Example: export ZSH_AI_EXTRA_KWARGS='{"temperature": 0.1}'

# Provider validation - only validates the selected provider
_zsh_ai_validate_config() {
    if [[ "$ZSH_AI_PROVIDER" != "anthropic" ]] && [[ "$ZSH_AI_PROVIDER" != "ollama" ]] && [[ "$ZSH_AI_PROVIDER" != "gemini" ]] && [[ "$ZSH_AI_PROVIDER" != "openai" ]]; then
        echo "zsh-ai: Error: Invalid provider '$ZSH_AI_PROVIDER'. Use 'anthropic', 'ollama', 'gemini', or 'openai'."
        return 1
    fi

    # Only check requirements for the selected provider
    case "$ZSH_AI_PROVIDER" in
        anthropic)
            if [[ -z "$ANTHROPIC_API_KEY" ]]; then
                echo "zsh-ai: Warning: ANTHROPIC_API_KEY not set. Plugin will not function."
                echo "zsh-ai: Set ANTHROPIC_API_KEY in .env or use ZSH_AI_PROVIDER=ollama for local models."
                return 1
            fi
            ;;
        gemini)
            if [[ -z "$GEMINI_API_KEY" ]]; then
                echo "zsh-ai: Warning: GEMINI_API_KEY not set. Plugin will not function."
                echo "zsh-ai: Set GEMINI_API_KEY in .env or use ZSH_AI_PROVIDER=ollama for local models."
                return 1
            fi
            ;;
        openai)
            if [[ -z "$OPENAI_API_KEY" ]]; then
                echo "zsh-ai: Warning: OPENAI_API_KEY not set. Plugin will not function."
                echo "zsh-ai: Set OPENAI_API_KEY in .env or use ZSH_AI_PROVIDER=ollama for local models."
                return 1
            fi
            ;;
        ollama)
            # Ollama doesn't require an API key, just a running server
            ;;
    esac

    return 0
}