#!/usr/bin/env zsh

# Google Gemini API provider for zsh-ai

# Function to call Gemini API
_zsh_ai_query_gemini() {
    local query="$1"
    local has_explanation="$2"  # "true" if --e flag is present
    local response

    # Build context
    local context=$(_zsh_ai_build_context)
    local escaped_context=$(_zsh_ai_escape_json "$context")
    local system_prompt=$(_zsh_ai_get_system_prompt "$escaped_context" "$has_explanation")
    local escaped_system_prompt=$(_zsh_ai_escape_json "$system_prompt")
    
    # Prepare the JSON payload - escape quotes in the query
    local escaped_query=$(_zsh_ai_escape_json "$query")
    local json_payload=$(cat <<EOF
{
    "contents": [
        {
            "role": "user",
            "parts": [
                {
                    "text": "$escaped_query"
                }
            ]
        }
    ],
    "systemInstruction": {
        "parts": [
            {
                "text": "$escaped_system_prompt"
            }
        ]
    },
    "generationConfig": {
        "temperature": $ZSH_AI_TEMPERATURE,
        "maxOutputTokens": $ZSH_AI_MAX_TOKENS,
        "thinkingConfig": {
            "thinkingBudget": 0
        }
    }
}
EOF
)
    # Merge extra kwargs if provided
    json_payload=$(_zsh_ai_merge_extra_kwargs "$json_payload")
    
    # Call the API
    # Note: Gemini API requires key in URL parameter (API design limitation)
    # This is the official Google API pattern and cannot be changed
    response=$(curl -s -w "\n%{http_code}" --max-time "$ZSH_AI_TIMEOUT" --connect-timeout 10 \
        "https://generativelanguage.googleapis.com/v1beta/models/${ZSH_AI_GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}" \
        --header "content-type: application/json" \
        --data "$json_payload" 2>&1)
    local curl_exit_code=$?

    # Check curl exit code
    if ! _zsh_ai_handle_curl_error "$curl_exit_code" "gemini"; then
        return 1
    fi

    # Extract HTTP status code (last line) and response body
    local http_code="${response##*$'\n'}"
    response="${response%$'\n'*}"

    # Check HTTP status code
    if ! _zsh_ai_handle_http_error "$http_code" "gemini"; then
        return 1
    fi

    # Debug: Uncomment to see raw response
    # echo "DEBUG: Raw response: $response" >&2

    # Parse response using common parser
    _zsh_ai_parse_response "$response" ".candidates[0].content.parts[0].text" "text"
}