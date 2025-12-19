#!/usr/bin/env zsh

# Configuration and validation for zsh-ai

# Load .env file
_zsh_ai_load_env() {
    local plugin_dir="${ZSH_AI_PLUGIN_DIR:-${0:A:h:h}}"
    local env_file=""

    if [[ -f "${plugin_dir}/.env" ]]; then
        env_file="${plugin_dir}/.env"
    elif [[ -f "${HOME}/.zsh-ai.env" ]]; then
        env_file="${HOME}/.zsh-ai.env"
    fi

    [[ -z "$env_file" ]] && return

    # Check file permissions for security
    local perms
    if [[ "$(uname)" == "Linux" ]]; then
        perms=$(stat -c %a "$env_file" 2>/dev/null)
    else
        # macOS and BSD
        perms=$(stat -f %Lp "$env_file" 2>/dev/null)
    fi

    if [[ -n "$perms" && "$perms" != "600" && "$perms" != "400" ]]; then
        echo "Warning: $env_file has insecure permissions ($perms). Recommended: 600" >&2
        echo "Run: chmod 600 $env_file" >&2
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" != *"="* ]] && continue
        local key="${line%%=*}"
        local value="${line#*=}"
        key="${key##[[:space:]]}"
        key="${key%%[[:space:]]}"
        value="${value##[[:space:]]}"
        value="${value%%[[:space:]]}"
        value="${value#\"}"
        value="${value%\"}"
        value="${value#\'}"
        value="${value%\'}"
        export "$key=$value"
    done < "$env_file"
}

# Note: Prompt loading has been removed. System prompts are now hardcoded in lib/utils.zsh
# to ensure consistent JSON output format and safety checks.
# User customization of prompts via prompt.yaml or environment variables is no longer supported.

# Load configurations
_zsh_ai_load_env

# Set default values
: ${ZSH_AI_PROVIDER:="anthropic"}
: ${ZSH_AI_OLLAMA_MODEL:="llama3.2"}
: ${ZSH_AI_OLLAMA_URL:="http://localhost:11434"}
: ${ZSH_AI_GEMINI_MODEL:="gemini-2.5-flash"}
: ${ZSH_AI_OPENAI_MODEL:="gpt-4o"}
: ${ZSH_AI_OPENAI_URL:="https://api.openai.com/v1/chat/completions"}
: ${ZSH_AI_ANTHROPIC_MODEL:="claude-haiku-4-5"}
: ${ZSH_AI_TIMEOUT:=30}
: ${ZSH_AI_PREFIX:="# "}
: ${ZSH_AI_LANG:="EN"}
: ${ZSH_AI_MAX_TOKENS:=256}
: ${ZSH_AI_TEMPERATURE:=0.3}

# Provider validation
_zsh_ai_validate_config() {
    case "$ZSH_AI_PROVIDER" in
        anthropic)
            [[ -z "$ANTHROPIC_API_KEY" ]] && {
                echo "zsh-ai: ANTHROPIC_API_KEY not set in .env"
                return 1
            }
            ;;
        gemini)
            [[ -z "$GEMINI_API_KEY" ]] && {
                echo "zsh-ai: GEMINI_API_KEY not set in .env"
                return 1
            }
            ;;
        openai)
            [[ -z "$OPENAI_API_KEY" ]] && {
                echo "zsh-ai: OPENAI_API_KEY not set in .env"
                return 1
            }
            ;;
        ollama)
            ;;
        *)
            echo "zsh-ai: Invalid provider '$ZSH_AI_PROVIDER'"
            return 1
            ;;
    esac
    return 0
}
