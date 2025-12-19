#!/usr/bin/env zsh

# Utility functions for zsh-ai

# Function to get the standardized system prompt for all providers
_zsh_ai_get_system_prompt() {
    local context="$1"

    # Use prompt from YAML if loaded, otherwise use default
    local base_prompt="${ZSH_AI_SYSTEM_PROMPT:-You are a zsh command generator. Generate syntactically correct zsh commands based on the user's natural language request.\n\nIMPORTANT RULES:\n1. Output ONLY the raw command - no explanations, no markdown, no backticks\n2. For arguments containing spaces or special characters, use single quotes\n3. Use double quotes only when variable expansion is needed\n4. Properly escape special characters within quotes\n\nExamples:\n- echo 'Hello World!' (spaces require quotes)\n- echo \"Current user: \$USER\" (variable expansion needs double quotes)\n- grep 'pattern with spaces' file.txt\n- find . -name '*.txt' (glob patterns in quotes)}"

    # Add custom prompt extension if provided
    if [[ -n "$ZSH_AI_PROMPT_EXTEND" ]]; then
        echo "${base_prompt}\n\n${ZSH_AI_PROMPT_EXTEND}\n\nContext:\n$context"
    else
        echo "${base_prompt}\n\nContext:\n$context"
    fi
}

# Function to properly escape strings for JSON
_zsh_ai_escape_json() {
    # Use printf and perl for reliable JSON escaping
    printf '%s' "$1" | perl -0777 -pe 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g; s/\r/\\r/g; s/\n/\\n/g; s/\f/\\f/g; s/\x08/\\b/g; s/[\x00-\x07\x0B\x0E-\x1F]//g'
}

# Validate JSON string
_zsh_ai_validate_json() {
    local json="$1"
    if command -v jq &> /dev/null; then
        echo "$json" | jq . >/dev/null 2>&1
        return $?
    fi
    return 0  # Skip validation if jq not available
}

# Standardized error message formatter
# Usage: _zsh_ai_error "provider_name" "error_message"
_zsh_ai_error() {
    local provider="$1"
    local message="$2"
    echo "Error: [$provider] $message"
}

# Handle curl exit codes with specific error messages
# Returns: error message string or empty if success
_zsh_ai_handle_curl_error() {
    local exit_code="$1"
    local provider="$2"

    case $exit_code in
        0)
            return 0  # Success
            ;;
        6)
            _zsh_ai_error "$provider" "Could not resolve host. Check your internet connection and API URL."
            return 1
            ;;
        7)
            _zsh_ai_error "$provider" "Connection refused. The API server may be down or unreachable."
            return 1
            ;;
        28)
            _zsh_ai_error "$provider" "Request timed out after ${ZSH_AI_TIMEOUT}s. The server may be slow or unresponsive."
            return 1
            ;;
        35)
            _zsh_ai_error "$provider" "SSL/TLS connection error. Check your system's SSL certificates."
            return 1
            ;;
        52)
            _zsh_ai_error "$provider" "Empty response from server. The API may be misconfigured."
            return 1
            ;;
        56)
            _zsh_ai_error "$provider" "Connection reset. Network or server issue occurred."
            return 1
            ;;
        *)
            _zsh_ai_error "$provider" "Network request failed (curl error $exit_code)."
            return 1
            ;;
    esac
}

# Handle HTTP status codes with specific error messages
# Returns: error message string or empty if success (200-299)
_zsh_ai_handle_http_error() {
    local http_code="$1"
    local provider="$2"

    # Success codes (200-299)
    if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
        return 0
    fi

    # Error codes
    case $http_code in
        400)
            _zsh_ai_error "$provider" "Bad request (HTTP 400). The request format may be invalid."
            return 1
            ;;
        401)
            _zsh_ai_error "$provider" "Authentication failed (HTTP 401). Check your API key in .env file."
            return 1
            ;;
        403)
            _zsh_ai_error "$provider" "Access forbidden (HTTP 403). Your API key may lack permissions."
            return 1
            ;;
        404)
            _zsh_ai_error "$provider" "API endpoint not found (HTTP 404). Check your API URL configuration."
            return 1
            ;;
        429)
            _zsh_ai_error "$provider" "Rate limit exceeded (HTTP 429). Please wait and try again."
            return 1
            ;;
        500)
            _zsh_ai_error "$provider" "Internal server error (HTTP 500). The API service is experiencing issues."
            return 1
            ;;
        502)
            _zsh_ai_error "$provider" "Bad gateway (HTTP 502). The API server is temporarily unavailable."
            return 1
            ;;
        503)
            _zsh_ai_error "$provider" "Service unavailable (HTTP 503). The API is temporarily down."
            return 1
            ;;
        *)
            _zsh_ai_error "$provider" "HTTP error $http_code occurred."
            return 1
            ;;
    esac
}

# Common JSON response parser for all providers
# Usage: _zsh_ai_parse_response "$response" "$jq_path" "$fallback_field"
# Example: _zsh_ai_parse_response "$response" ".content[0].text" "text"
_zsh_ai_parse_response() {
    local response="$1"
    local jq_path="$2"
    local fallback_field="$3"

    # Try using jq if available
    if command -v jq &> /dev/null; then
        local result=$(echo "$response" | jq -r "${jq_path} // empty" 2>/dev/null)
        if [[ -z "$result" ]]; then
            # Check for error message
            local error=$(echo "$response" | jq -r '.error.message // .error // empty' 2>/dev/null)
            if [[ -n "$error" ]]; then
                echo "Error: $error"
            else
                # Show truncated response for debugging
                local preview="${response:0:200}"
                [[ ${#response} -gt 200 ]] && preview="${preview}..."
                echo "Error: Failed to parse API response"
                echo "Response preview: $preview"
            fi
            return 1
        fi
        # Clean up the response - remove newlines and trailing whitespace
        result=$(echo "$result" | tr -d '\n' | sed 's/[[:space:]]*$//')
        echo "$result"
    else
        # Fallback parsing without jq
        local result=$(echo "$response" | sed -n "s/.*\"${fallback_field}\":\"\\([^\"]*\\)\".*/\\1/p" | head -1)

        # If simple extraction failed, try complex approach for multiline responses
        if [[ -z "$result" ]]; then
            result=$(echo "$response" | perl -0777 -ne "print \$1 if /\"${fallback_field}\":\"((?:[^\"\\\\]|\\\\.)*)\"/" 2>/dev/null)
        fi

        if [[ -z "$result" ]]; then
            # Check for API error in response
            if [[ "$response" == *'"error"'* ]]; then
                local error_msg=$(echo "$response" | sed -n 's/.*"message":"\([^"]*\)".*/\1/p' | head -1)
                if [[ -n "$error_msg" ]]; then
                    echo "Error: $error_msg"
                    return 1
                fi
            fi
            # Show truncated response for debugging
            local preview="${response:0:200}"
            [[ ${#response} -gt 200 ]] && preview="${preview}..."
            echo "Error: Failed to parse API response (install jq for better reliability)"
            echo "Response preview: $preview"
            return 1
        fi

        # Unescape JSON string (handle \n, \t, etc.) and clean up
        result=$(echo "$result" | sed 's/\\n/\n/g; s/\\t/\t/g; s/\\r/\r/g; s/\\"/"/g; s/\\\\/\\/g')
        # Remove trailing newlines and spaces
        result=$(echo "$result" | sed 's/[[:space:]]*$//')
        echo "$result"
    fi
}

# Function to merge extra kwargs into JSON payload
# Takes base JSON and merges ZSH_AI_EXTRA_KWARGS into it
_zsh_ai_merge_extra_kwargs() {
    local base_json="$1"

    # If no extra kwargs, return base JSON as-is
    if [[ -z "$ZSH_AI_EXTRA_KWARGS" ]]; then
        printf '%s' "$base_json"
        return
    fi

    # Validate extra kwargs JSON before using
    if ! _zsh_ai_validate_json "$ZSH_AI_EXTRA_KWARGS"; then
        echo "Warning: ZSH_AI_EXTRA_KWARGS is not valid JSON, ignoring" >&2
        printf '%s' "$base_json"
        return
    fi

    # Use jq if available for proper JSON merge
    # Use -c for compact output to preserve escaped characters
    if command -v jq &> /dev/null; then
        printf '%s' "$base_json" | jq -c --argjson extra "$ZSH_AI_EXTRA_KWARGS" '. * $extra' 2>/dev/null || printf '%s' "$base_json"
    else
        # Fallback: simple string manipulation for common cases
        # Remove trailing } from base, add extra kwargs
        local extra_cleaned="${ZSH_AI_EXTRA_KWARGS#\{}"
        extra_cleaned="${extra_cleaned%\}}"
        if [[ -n "$extra_cleaned" ]]; then
            # Insert extra kwargs before the last }
            printf '%s' "${base_json%\}}, ${extra_cleaned}}"
        else
            printf '%s' "$base_json"
        fi
    fi
}

# Get language instruction for explanation prompt
_zsh_ai_get_lang_instruction() {
    local lang="${ZSH_AI_LANG:-EN}"
    case "$lang" in
        KO|ko)
            echo "You MUST respond in Korean (한국어)."
            ;;
        JA|ja)
            echo "You MUST respond in Japanese (日本語)."
            ;;
        ZH|zh)
            echo "You MUST respond in Chinese (中文)."
            ;;
        DE|de)
            echo "You MUST respond in German (Deutsch)."
            ;;
        FR|fr)
            echo "You MUST respond in French (Français)."
            ;;
        ES|es)
            echo "You MUST respond in Spanish (Español)."
            ;;
        *)
            echo "You MUST respond in English."
            ;;
    esac
}

# System prompt for explaining commands
_zsh_ai_get_explain_prompt() {
    local lang_instruction=$(_zsh_ai_get_lang_instruction)
    local default_prompt="You are a shell command explainer. Given a shell command, provide a brief, clear explanation of what it does.\n\nIMPORTANT RULES:\n1. Output ONLY the explanation text - no markdown, no backticks, no formatting\n2. Keep it concise (1-2 sentences maximum)\n3. Focus on what the command does, not how to use it\n4. Use simple, clear language\n\nExample:\nCommand: find . -name '*.txt' -mtime -1\nExplanation: Finds all .txt files in current directory modified within the last day"

    # Use custom prompt from YAML if available, otherwise use default
    local base_prompt="${ZSH_AI_EXPLAIN_PROMPT:-$default_prompt}"

    # Always prepend language instruction
    echo "${lang_instruction}\n\n${base_prompt}"
}

# Function to get explanation for a command via second LLM call
_zsh_ai_explain_command() {
    local cmd="$1"
    local explanation

    # Build a simple query for explanation
    local explain_query="Command: $cmd\nExplanation:"

    # Temporarily override the system prompt for explanation
    local original_prompt="$ZSH_AI_SYSTEM_PROMPT"
    export ZSH_AI_SYSTEM_PROMPT=$(_zsh_ai_get_explain_prompt)

    # Query the LLM for explanation
    explanation=$(_zsh_ai_query "$explain_query")

    # Restore original prompt
    if [[ -n "$original_prompt" ]]; then
        export ZSH_AI_SYSTEM_PROMPT="$original_prompt"
    else
        unset ZSH_AI_SYSTEM_PROMPT
    fi

    # Return explanation (clean up any leading/trailing whitespace)
    echo "$explanation" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

# Function to format command with explanation as inline comment
_zsh_ai_format_with_explanation() {
    local cmd="$1"
    local explanation="$2"

    # Format: command  # explanation (inline comment)
    # This avoids infinite loop when ZSH_AI_PREFIX starts with #
    # The # after command is treated as shell comment and ignored during execution
    echo "$cmd  # $explanation"
}

# Main query function that routes to the appropriate provider
_zsh_ai_query() {
    local query="$1"
    
    if [[ "$ZSH_AI_PROVIDER" == "ollama" ]]; then
        # Check if Ollama is running first
        if ! _zsh_ai_check_ollama; then
            echo "Error: Cannot connect to Ollama"
            echo "  URL: $ZSH_AI_OLLAMA_URL"
            echo "  ${ZSH_AI_OLLAMA_CHECK_ERROR:-Unknown error}"
            echo ""
            echo "To fix:"
            echo "  1. Start Ollama: ollama serve"
            echo "  2. Or check URL in .env: ZSH_AI_OLLAMA_URL"
            return 1
        fi
        _zsh_ai_query_ollama "$query"
    elif [[ "$ZSH_AI_PROVIDER" == "gemini" ]]; then
        _zsh_ai_query_gemini "$query"
    elif [[ "$ZSH_AI_PROVIDER" == "openai" ]]; then
        _zsh_ai_query_openai "$query"
    else
        _zsh_ai_query_anthropic "$query"
    fi
}

# Parse query for --e flag
# Returns: sets _ZSH_AI_EXPLAIN_FLAG and _ZSH_AI_CLEAN_QUERY
_zsh_ai_parse_query() {
    local query="$1"
    _ZSH_AI_EXPLAIN_FLAG=0
    _ZSH_AI_CLEAN_QUERY="$query"

    # Check for --e flag at the end of query
    if [[ "$query" == *" --e" ]]; then
        _ZSH_AI_EXPLAIN_FLAG=1
        _ZSH_AI_CLEAN_QUERY="${query% --e}"
    elif [[ "$query" == *"--e" ]]; then
        _ZSH_AI_EXPLAIN_FLAG=1
        _ZSH_AI_CLEAN_QUERY="${query%--e}"
    fi

    # Trim trailing whitespace from clean query
    _ZSH_AI_CLEAN_QUERY="${_ZSH_AI_CLEAN_QUERY%"${_ZSH_AI_CLEAN_QUERY##*[![:space:]]}"}"
}

# Shared function to handle AI command execution
_zsh_ai_execute_command() {
    local query="$1"

    # Parse query for flags
    _zsh_ai_parse_query "$query"
    local explain_flag=$_ZSH_AI_EXPLAIN_FLAG
    local clean_query="$_ZSH_AI_CLEAN_QUERY"

    # Get the command from LLM
    local cmd=$(_zsh_ai_query "$clean_query")

    if [[ -n "$cmd" ]] && [[ "$cmd" != "Error:"* ]]; then
        # Check for dangerous commands first (highest priority)
        if _zsh_ai_check_dangerous_command "$cmd"; then
            # Safe command - proceed with explanation if requested
            if [[ $explain_flag -eq 1 ]]; then
                local explanation=$(_zsh_ai_explain_command "$cmd")
                if [[ -n "$explanation" ]] && [[ "$explanation" != "Error:"* ]]; then
                    _zsh_ai_format_with_explanation "$cmd" "$explanation"
                else
                    # If explanation failed, just return the command
                    echo "$cmd"
                fi
            else
                echo "$cmd"
            fi
        else
            # Dangerous command detected - add warning comment (ignore --e flag)
            _zsh_ai_add_warning_comment "$cmd" "$_ZSH_AI_DANGER_WARNING"
        fi
        return 0
    else
        echo "$cmd"
        return 1
    fi
}

# Optional: Add a helper function for users who prefer explicit commands
zsh-ai() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: zsh-ai \"your natural language command\" [--e]"
        echo ""
        echo "Options:"
        echo "  --e    Add explanation comment above the generated command"
        echo ""
        echo "Examples:"
        echo "  zsh-ai \"find all python files modified today\""
        echo "  zsh-ai \"list large files\" --e"
        echo ""
        echo "Current provider: $ZSH_AI_PROVIDER"
        if [[ "$ZSH_AI_PROVIDER" == "ollama" ]]; then
            echo "Ollama model: $ZSH_AI_OLLAMA_MODEL"
        elif [[ "$ZSH_AI_PROVIDER" == "gemini" ]]; then
            echo "Gemini model: $ZSH_AI_GEMINI_MODEL"
        elif [[ "$ZSH_AI_PROVIDER" == "openai" ]]; then
            echo "OpenAI model: $ZSH_AI_OPENAI_MODEL"
        fi
        return 1
    fi
    
    local query="$*"
    
    # Animation frames - rotating dots (same as widget)
    local dots=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local frame=0
    
    # Create a temp file for the response
    local tmpfile=$(mktemp)
    trap "rm -f '$tmpfile'" RETURN INT TERM

    # Disable job control notifications (same as widget)
    setopt local_options no_monitor no_notify

    # Start the API query in background
    (_zsh_ai_execute_command "$query" > "$tmpfile" 2>&1) &
    local pid=$!
    
    # Animate while waiting
    while kill -0 $pid 2>/dev/null; do
        echo -ne "\r${dots[$((frame % ${#dots[@]}))]} "
        ((frame++))
        sleep 0.1
    done
    
    # Clear the line
    echo -ne "\r\033[K"
    
    # Get the response and exit code
    wait $pid
    local exit_code=$?
    local cmd=$(cat "$tmpfile")
    
    if [[ $exit_code -eq 0 ]] && [[ -n "$cmd" ]] && [[ "$cmd" != "Error:"* ]]; then
        # Put the command in the ZLE buffer (same as # method)
        print -z "$cmd"
    else
        # Show error with better visibility
        echo ""  # Blank line for spacing
        print -P "%F{red}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%f"
        print -P "%F{red}❌ Failed to generate command%f"
        if [[ -n "$cmd" ]]; then
            print -P "%F{red}$cmd%f"
        fi
        print -P "%F{red}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%f"
        echo ""  # Blank line for spacing
        return 1
    fi
}
