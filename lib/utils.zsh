#!/usr/bin/env zsh

# Utility functions for zsh-ai

# Function to get the standardized system prompt for all providers
# Note: This prompt is hardcoded and cannot be customized by users to ensure
# consistent JSON output and safety checks.
_zsh_ai_get_system_prompt() {
    local context="$1"
    local has_explanation="$2"  # "true" if --e flag is present

    # Get language instruction
    local lang_instruction=$(_zsh_ai_get_lang_instruction)

    # Build JSON format specification based on --e flag
    local json_format
    if [[ "$has_explanation" == "true" ]]; then
        json_format='{"command": "your zsh command here", "explanation": "brief explanation", "warning": null}'
    else
        json_format='{"command": "your zsh command here", "warning": null}'
    fi

    # Hardcoded system prompt (cannot be overridden by users)
    local base_prompt="You are a zsh command generator. Generate syntactically correct zsh commands based on the user's natural language request.

CRITICAL: You MUST respond with ONLY valid JSON in this exact format:
${json_format}

IMPORTANT RULES:
1. Output ONLY raw JSON - no markdown code blocks, no backticks, no explanations outside JSON
2. The \"command\" field must contain a syntactically correct zsh command
3. For arguments containing spaces or special characters, use single quotes
4. Use double quotes only when variable expansion is needed
5. Properly escape special characters within quotes

SAFETY RULES:
6. If the command is dangerous (can cause data loss, system damage, or security issues), set \"warning\" with a clear explanation of the danger and suggest safer alternatives
7. Examples of dangerous commands: rm -rf /, dd to disk devices, chmod 777, curl|bash, fork bombs
8. If command is safe, set \"warning\" to null
9. NEVER set both \"explanation\" and \"warning\" - use only one based on safety"

    if [[ "$has_explanation" == "true" ]]; then
        base_prompt="${base_prompt}
10. The \"explanation\" field should briefly describe what the command does (1-2 sentences)
11. ${lang_instruction}"
    else
        base_prompt="${base_prompt}
10. ${lang_instruction} (for warning messages only)"
    fi

    base_prompt="${base_prompt}

Examples of good command quoting:
- echo 'Hello World!' (spaces require quotes)
- echo \"Current user: \$USER\" (variable expansion needs double quotes)
- grep 'pattern with spaces' file.txt
- find . -name '*.txt' (glob patterns in quotes)

Context:
${context}"

    echo "$base_prompt"
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

# Fix common JSON formatting issues
_zsh_ai_fix_json() {
    local broken_json="$1"

    # Remove markdown code blocks if present
    broken_json=$(echo "$broken_json" | sed 's/^```json\?//; s/```$//')

    # Remove leading/trailing whitespace
    broken_json=$(echo "$broken_json" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

    # Remove trailing commas before closing braces/brackets
    broken_json=$(echo "$broken_json" | sed 's/,[[:space:]]*}/}/g; s/,[[:space:]]*\]/]/g')

    # Try to fix common escaping issues (simple cases only)
    # This is conservative - we don't want to break valid JSON

    echo "$broken_json"
}

# Parse LLM's JSON response and extract fields
# Returns: Sets global variables _ZSH_AI_CMD, _ZSH_AI_EXPLANATION, _ZSH_AI_WARNING
_zsh_ai_parse_llm_json() {
    local content="$1"

    # Initialize return variables
    _ZSH_AI_CMD=""
    _ZSH_AI_EXPLANATION=""
    _ZSH_AI_WARNING=""

    # Try to validate JSON first
    if ! _zsh_ai_validate_json "$content"; then
        # Try to fix common JSON issues
        content=$(_zsh_ai_fix_json "$content")

        # Validate again after fix
        if ! _zsh_ai_validate_json "$content"; then
            # JSON parsing failed - try regex fallback
            _ZSH_AI_CMD=$(echo "$content" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
            if [[ -z "$_ZSH_AI_CMD" ]]; then
                echo "Error: Failed to parse JSON response from LLM"
                return 1
            fi
            # Try to extract warning/explanation with regex
            _ZSH_AI_WARNING=$(echo "$content" | sed -n 's/.*"warning"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
            _ZSH_AI_EXPLANATION=$(echo "$content" | sed -n 's/.*"explanation"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
            return 0
        fi
    fi

    # JSON is valid, parse with jq if available
    if command -v jq &> /dev/null; then
        _ZSH_AI_CMD=$(echo "$content" | jq -r '.command // empty' 2>/dev/null)
        _ZSH_AI_WARNING=$(echo "$content" | jq -r '.warning // empty' 2>/dev/null)
        _ZSH_AI_EXPLANATION=$(echo "$content" | jq -r '.explanation // empty' 2>/dev/null)

        # Convert "null" string to empty
        [[ "$_ZSH_AI_WARNING" == "null" ]] && _ZSH_AI_WARNING=""
        [[ "$_ZSH_AI_EXPLANATION" == "null" ]] && _ZSH_AI_EXPLANATION=""
    else
        # Fallback: Use sed/grep to extract fields
        _ZSH_AI_CMD=$(echo "$content" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
        _ZSH_AI_WARNING=$(echo "$content" | sed -n 's/.*"warning"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
        _ZSH_AI_EXPLANATION=$(echo "$content" | sed -n 's/.*"explanation"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
    fi

    # Validate that we got at least a command
    if [[ -z "$_ZSH_AI_CMD" ]]; then
        echo "Error: No command found in LLM response"
        return 1
    fi

    return 0
}

# Debug logging function (only when ZSH_AI_DEV is set)
_zsh_ai_debug_log() {
    [[ -z "$ZSH_AI_DEV" ]] && return

    local plugin_dir="${ZSH_AI_PLUGIN_DIR:-${0:A:h:h}}"
    local log_file="${plugin_dir}/zsh-ai-debug.log"

    # Get current timestamp
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Append to log file
    echo "" >> "$log_file"
    echo "=== [$timestamp] ===" >> "$log_file"
    echo "$@" >> "$log_file"
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
        # Clean up the response - convert newlines to spaces, remove trailing whitespace
        result=$(echo "$result" | tr '\n' ' ' | sed 's/[[:space:]]*$//; s/[[:space:]]\{2,\}/ /g')
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
    local has_explanation="$2"  # "true" if --e flag is present

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
        _zsh_ai_query_ollama "$query" "$has_explanation"
    elif [[ "$ZSH_AI_PROVIDER" == "gemini" ]]; then
        _zsh_ai_query_gemini "$query" "$has_explanation"
    elif [[ "$ZSH_AI_PROVIDER" == "openai" ]]; then
        _zsh_ai_query_openai "$query" "$has_explanation"
    else
        _zsh_ai_query_anthropic "$query" "$has_explanation"
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

    # Convert explain_flag to string for function signature
    local has_explanation="false"
    [[ $explain_flag -eq 1 ]] && has_explanation="true"

    # Get JSON response from LLM
    local llm_response=$(_zsh_ai_query "$clean_query" "$has_explanation")

    # Debug logging (only if ZSH_AI_DEV is set)
    if [[ -n "$ZSH_AI_DEV" ]]; then
        _zsh_ai_debug_log "Query: $clean_query"
        _zsh_ai_debug_log "Has Explanation: $has_explanation"
        _zsh_ai_debug_log "LLM Response (raw):"
        _zsh_ai_debug_log "$llm_response"
    fi

    # Check for error in raw response
    if [[ "$llm_response" == "Error:"* ]]; then
        echo "$llm_response"
        return 1
    fi

    # Parse JSON response
    if ! _zsh_ai_parse_llm_json "$llm_response"; then
        # Parsing failed - error message already printed by parser
        return 1
    fi

    # Extract parsed values from global variables
    local cmd="$_ZSH_AI_CMD"
    local explanation="$_ZSH_AI_EXPLANATION"
    local warning="$_ZSH_AI_WARNING"

    # Debug logging for parsed values
    if [[ -n "$ZSH_AI_DEV" ]]; then
        _zsh_ai_debug_log "Parsed Command: $cmd"
        _zsh_ai_debug_log "Parsed Explanation: $explanation"
        _zsh_ai_debug_log "Parsed Warning: $warning"
    fi

    # Fallback safety check: If LLM didn't provide warning, check with regex patterns
    if [[ -z "$warning" ]]; then
        if ! _zsh_ai_check_dangerous_command "$cmd"; then
            # Dangerous command detected by fallback - use regex warning
            warning="$_ZSH_AI_DANGER_WARNING"
        fi
    fi

    # Format final output
    if [[ -n "$warning" ]]; then
        # Dangerous command - add warning (ignore explanation even if present)
        _zsh_ai_add_warning_comment "$cmd" "$warning"
    elif [[ -n "$explanation" ]]; then
        # Safe command with explanation
        _zsh_ai_format_with_explanation "$cmd" "$explanation"
    else
        # Safe command without explanation
        echo "$cmd"
    fi

    return 0
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
