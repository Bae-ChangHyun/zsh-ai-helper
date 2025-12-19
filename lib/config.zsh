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

# Load prompt from YAML file
_zsh_ai_load_prompt() {
    local plugin_dir="${ZSH_AI_PLUGIN_DIR:-${0:A:h:h}}"
    local yaml_file="${plugin_dir}/prompt.yaml"

    [[ ! -f "$yaml_file" ]] && return

    local in_system_prompt=false
    local in_prompt_extend=false
    local in_explain_prompt=false
    local system_prompt=""
    local prompt_extend=""
    local explain_prompt=""

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Check for key starts
        if [[ "$line" =~ ^system_prompt:.*\|[[:space:]]*$ ]]; then
            in_system_prompt=true
            in_prompt_extend=false
            in_explain_prompt=false
            continue
        elif [[ "$line" =~ ^prompt_extend:.*\|[[:space:]]*$ ]]; then
            in_prompt_extend=true
            in_system_prompt=false
            in_explain_prompt=false
            continue
        elif [[ "$line" =~ ^explain_prompt:.*\|[[:space:]]*$ ]]; then
            in_explain_prompt=true
            in_system_prompt=false
            in_prompt_extend=false
            continue
        elif [[ "$line" =~ ^[a-z_]+: ]] && [[ ! "$line" =~ ^\# ]]; then
            in_system_prompt=false
            in_prompt_extend=false
            in_explain_prompt=false
            continue
        fi

        # Skip comments
        [[ "$line" =~ ^[[:space:]]*\# ]] && continue

        # Collect multiline values (indented lines)
        if [[ "$line" =~ ^[[:space:]][[:space:]] ]]; then
            local content="${line#  }"  # Remove 2-space indent
            if $in_system_prompt; then
                [[ -n "$system_prompt" ]] && system_prompt="${system_prompt}\n"
                system_prompt="${system_prompt}${content}"
            elif $in_prompt_extend; then
                [[ -n "$prompt_extend" ]] && prompt_extend="${prompt_extend}\n"
                prompt_extend="${prompt_extend}${content}"
            elif $in_explain_prompt; then
                [[ -n "$explain_prompt" ]] && explain_prompt="${explain_prompt}\n"
                explain_prompt="${explain_prompt}${content}"
            fi
        fi
    done < "$yaml_file"

    # Export as environment variables
    [[ -n "$system_prompt" ]] && export ZSH_AI_SYSTEM_PROMPT="$system_prompt"
    [[ -n "$prompt_extend" ]] && export ZSH_AI_PROMPT_EXTEND="$prompt_extend"
    [[ -n "$explain_prompt" ]] && export ZSH_AI_EXPLAIN_PROMPT="$explain_prompt"
}

# Load configurations
_zsh_ai_load_env
_zsh_ai_load_prompt

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
