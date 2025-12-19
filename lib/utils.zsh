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

# Fix common JSON formatting issues before parsing
_zsh_ai_fix_json() {
    local broken_json="$1"

    # Remove markdown code blocks if present
    broken_json=$(echo "$broken_json" | sed 's/^```json\?//; s/```$//')

    # Remove leading/trailing whitespace
    broken_json=$(echo "$broken_json" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

    # Remove trailing commas before closing braces/brackets
    broken_json=$(echo "$broken_json" | sed 's/,[[:space:]]*}/}/g; s/,[[:space:]]*\]/]/g')

    echo "$broken_json"
}

# Parse JSON with Python (fallback when jq is not available)
_zsh_ai_parse_json_python() {
    local json="$1"
    local field="$2"

    # Use printf to avoid heredoc issues with special characters
    printf '%s' "$json" | python3 -c "
import json
import sys
try:
    data = json.loads(sys.stdin.read())
    value = data.get('$field', '')
    if value is None:
        value = ''
    print(value, end='')
except Exception as e:
    sys.exit(1)
" 2>/dev/null
}

# Parse LLM's response - try JSON first, then simple text extraction
# Returns: Sets global variables _ZSH_AI_CMD, _ZSH_AI_EXPLANATION, _ZSH_AI_WARNING
_zsh_ai_parse_llm_json() {
    local content="$1"

    # Initialize
    _ZSH_AI_CMD=""
    _ZSH_AI_EXPLANATION=""
    _ZSH_AI_WARNING=""

    # Unescape the content first to make it easier to parse
    local unescaped=$(printf '%s' "$content" | sed 's/\\n/ /g; s/\\t/ /g; s/\\r//g; s/\\"/"/g; s/\\\\/\\/g')

    # Try jq first (if available and content looks like JSON)
    if command -v jq &> /dev/null && [[ "$unescaped" == "{"* ]]; then
        _ZSH_AI_CMD=$(printf '%s' "$unescaped" | jq -r '.command // empty' 2>/dev/null)
        _ZSH_AI_WARNING=$(printf '%s' "$unescaped" | jq -r '.warning // empty' 2>/dev/null)
        _ZSH_AI_EXPLANATION=$(printf '%s' "$unescaped" | jq -r '.explanation // empty' 2>/dev/null)

        # Clean up
        [[ "$_ZSH_AI_WARNING" == "null" || "$_ZSH_AI_WARNING" == "" ]] && _ZSH_AI_WARNING=""
        [[ "$_ZSH_AI_EXPLANATION" == "null" || "$_ZSH_AI_EXPLANATION" == "" ]] && _ZSH_AI_EXPLANATION=""
    fi

    # If jq failed, extract directly from text (ignoring JSON validity)
    if [[ -z "$_ZSH_AI_CMD" ]]; then
        # Match from "command":" to "warning or "explanation field
        _ZSH_AI_CMD=$(printf '%s' "$unescaped" | perl -0777 -ne '
            if (/"command"\s*:\s*"(.*?)"\s*,\s*"(?:warning|explanation)/) {
                print $1;
            }
        ')
    fi

    # Extract warning if not already extracted
    if [[ -z "$_ZSH_AI_WARNING" ]]; then
        _ZSH_AI_WARNING=$(printf '%s' "$unescaped" | perl -0777 -ne '
            if (/"warning"\s*:\s*"(.*?)"/) {
                print $1 unless $1 eq "null";
            }
        ')
    fi

    # Extract explanation if not already extracted
    if [[ -z "$_ZSH_AI_EXPLANATION" ]]; then
        _ZSH_AI_EXPLANATION=$(printf '%s' "$unescaped" | perl -0777 -ne '
            if (/"explanation"\s*:\s*"(.*?)"/) {
                print $1 unless $1 eq "null";
            }
        ')
    fi

    # Validate
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

    # Append to log file (no extra formatting, just the message)
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
        # Extract the content field (returns as JSON string with quotes)
        local result=$(printf '%s' "$response" | jq "${jq_path} // empty" 2>/dev/null)
        if [[ -z "$result" || "$result" == "null" ]]; then
            # Check for error message
            local error=$(printf '%s' "$response" | jq -r '.error.message // .error // empty' 2>/dev/null)
            if [[ -n "$error" ]]; then
                echo "Error: $error"
            else
                echo "Error: Failed to parse API response"
                # In dev mode, show full response; otherwise truncate
                if [[ -n "$ZSH_AI_DEV" ]]; then
                    echo "Response (full): $response"
                else
                    local preview="${response:0:200}"
                    [[ ${#response} -gt 200 ]] && preview="${preview}..."
                    echo "Response preview: $preview"
                fi
            fi
            return 1
        fi
        # Remove outer quotes only (keep escaped content as-is)
        result=$(printf '%s' "$result" | sed 's/^"//; s/"$//')
        printf '%s\n' "$result"
    else
        # Fallback parsing without jq
        local result=$(printf '%s' "$response" | sed -n "s/.*\"${fallback_field}\":\"\\([^\"]*\\)\".*/\\1/p" | head -1)

        # If simple extraction failed, try complex approach for multiline responses
        if [[ -z "$result" ]]; then
            result=$(printf '%s' "$response" | perl -0777 -ne "print \$1 if /\"${fallback_field}\":\"((?:[^\"\\\\]|\\\\.)*)\"/" 2>/dev/null)
        fi

        if [[ -z "$result" ]]; then
            # Check for API error in response
            if [[ "$response" == *'"error"'* ]]; then
                local error_msg=$(printf '%s' "$response" | sed -n 's/.*"message":"\([^"]*\)".*/\1/p' | head -1)
                if [[ -n "$error_msg" ]]; then
                    echo "Error: $error_msg"
                    return 1
                fi
            fi
            echo "Error: Failed to parse API response (install jq for better reliability)"
            # In dev mode, show full response; otherwise truncate
            if [[ -n "$ZSH_AI_DEV" ]]; then
                echo "Response (full): $response"
            else
                local preview="${response:0:200}"
                [[ ${#response} -gt 200 ]] && preview="${preview}..."
                echo "Response preview: $preview"
            fi
            return 1
        fi

        # Unescape JSON string (handle \n, \t, etc.) and clean up
        result=$(printf '%s' "$result" | sed 's/\\n/\n/g; s/\\t/\t/g; s/\\r/\r/g; s/\\"/"/g; s/\\\\/\\/g')
        # Remove trailing newlines and spaces
        result=$(printf '%s' "$result" | sed 's/[[:space:]]*$//')
        printf '%s\n' "$result"
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

    # Debug logging line 1 & 2 (always log query and raw response)
    if [[ -n "$ZSH_AI_DEV" ]]; then
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        _zsh_ai_debug_log "[${timestamp}] Query(--e=$has_explanation): $clean_query"
        _zsh_ai_debug_log "LLM Raw: $llm_response"
        _zsh_ai_debug_log "#######################"
    fi

    # Check for error in raw response
    if [[ "$llm_response" == "Error:"* ]]; then
        [[ -n "$ZSH_AI_DEV" ]] && _zsh_ai_debug_log "Parsed: FAILED - Error response"
        echo "$llm_response"
        return 1
    fi

    # Parse JSON response
    if ! _zsh_ai_parse_llm_json "$llm_response"; then
        # Parsing failed - error message already printed by parser
        [[ -n "$ZSH_AI_DEV" ]] && _zsh_ai_debug_log "Parsed: FAILED - JSON parse error"
        return 1
    fi

    # Extract parsed values from global variables
    local cmd="$_ZSH_AI_CMD"
    local explanation="$_ZSH_AI_EXPLANATION"
    local warning="$_ZSH_AI_WARNING"

    # Debug logging line 3 (parsed values)
    if [[ -n "$ZSH_AI_DEV" ]]; then
        _zsh_ai_debug_log "Parsed: cmd='$cmd' | exp='$explanation' | warn='$warning'"
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
