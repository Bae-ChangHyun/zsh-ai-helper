#!/usr/bin/env zsh

# Ollama API provider for zsh-ai

# Function to check if Ollama is running
# Returns 0 if running, 1 if not
# Sets ZSH_AI_OLLAMA_CHECK_ERROR with detailed error message
_zsh_ai_check_ollama() {
    local response
    local curl_exit_code

    # Try to connect to Ollama API
    response=$(curl -s --max-time 5 --connect-timeout 3 -w "\n%{http_code}" "${ZSH_AI_OLLAMA_URL}/api/tags" 2>&1)
    curl_exit_code=$?

    # Check curl exit code for connection errors
    if [[ $curl_exit_code -ne 0 ]]; then
        case $curl_exit_code in
            6)
                ZSH_AI_OLLAMA_CHECK_ERROR="Could not resolve host. Check ZSH_AI_OLLAMA_URL setting."
                ;;
            7)
                ZSH_AI_OLLAMA_CHECK_ERROR="Connection refused at ${ZSH_AI_OLLAMA_URL}. Is Ollama running?"
                ;;
            28)
                ZSH_AI_OLLAMA_CHECK_ERROR="Connection timed out. Ollama may be starting up or unresponsive."
                ;;
            *)
                ZSH_AI_OLLAMA_CHECK_ERROR="Connection failed (curl error $curl_exit_code)."
                ;;
        esac
        return 1
    fi

    # Extract HTTP status code (last line)
    local http_code="${response##*$'\n'}"

    # Check HTTP status
    if [[ "$http_code" != "200" ]]; then
        ZSH_AI_OLLAMA_CHECK_ERROR="Ollama returned HTTP $http_code. Server may be misconfigured."
        return 1
    fi

    return 0
}

# Function to call Ollama API
_zsh_ai_query_ollama() {
    local query="$1"
    local has_explanation="$2"  # "true" if --e flag is present
    local response

    # Build context
    local context=$(_zsh_ai_build_context)
    local escaped_context=$(_zsh_ai_escape_json "$context")
    local system_prompt=$(_zsh_ai_get_system_prompt "$escaped_context" "$has_explanation")
    local escaped_system_prompt=$(_zsh_ai_escape_json "$system_prompt")
    
    # Prepare the JSON payload
    local escaped_query=$(_zsh_ai_escape_json "$query")
    local json_payload=$(cat <<EOF
{
    "model": "$ZSH_AI_OLLAMA_MODEL",
    "prompt": "$escaped_query",
    "system": "$escaped_system_prompt",
    "stream": false,
    "think": false,
    "options": {
        "temperature": $ZSH_AI_TEMPERATURE,
        "num_predict": $ZSH_AI_MAX_TOKENS
    }
}
EOF
)
    # Merge extra kwargs if provided
    json_payload=$(_zsh_ai_merge_extra_kwargs "$json_payload")
    
    # Call the API
    response=$(curl -s -w "\n%{http_code}" --max-time "$ZSH_AI_TIMEOUT" --connect-timeout 10 \
        "${ZSH_AI_OLLAMA_URL}/api/generate" \
        --header "content-type: application/json" \
        --data "$json_payload" 2>&1)
    local curl_exit_code=$?

    # Check curl exit code
    if ! _zsh_ai_handle_curl_error "$curl_exit_code" "ollama"; then
        return 1
    fi

    # Extract HTTP status code (last line) and response body
    local http_code="${response##*$'\n'}"
    response="${response%$'\n'*}"

    # Check HTTP status code
    if ! _zsh_ai_handle_http_error "$http_code" "ollama"; then
        return 1
    fi

    # Parse response using common parser
    _zsh_ai_parse_response "$response" ".response" "response"
}