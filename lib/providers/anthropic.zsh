#!/usr/bin/env zsh

# Anthropic Claude API provider for zsh-ai

# Function to call Anthropic API
_zsh_ai_query_anthropic() {
    local query="$1"
    local response
    
    # Build context
    local context=$(_zsh_ai_build_context)
    local escaped_context=$(_zsh_ai_escape_json "$context")
    local system_prompt=$(_zsh_ai_get_system_prompt "$escaped_context")
    local escaped_system_prompt=$(_zsh_ai_escape_json "$system_prompt")
    
    # Prepare the JSON payload - escape quotes in the query
    local escaped_query=$(_zsh_ai_escape_json "$query")
    local json_payload=$(cat <<EOF
{
    "model": "$ZSH_AI_ANTHROPIC_MODEL",
    "max_tokens": $ZSH_AI_MAX_TOKENS,
    "temperature": $ZSH_AI_TEMPERATURE,
    "system": "$escaped_system_prompt",
    "messages": [
        {
            "role": "user",
            "content": "$escaped_query"
        }
    ]
}
EOF
)
    # Merge extra kwargs if provided
    json_payload=$(_zsh_ai_merge_extra_kwargs "$json_payload")
    
    # Call the API
    # Use temporary file for headers to prevent API key exposure in process list
    local header_file=$(mktemp)
    chmod 600 "$header_file"
    cat > "$header_file" <<HEADERS
x-api-key: $ANTHROPIC_API_KEY
anthropic-version: 2023-06-01
content-type: application/json
HEADERS

    response=$(curl -s --max-time "$ZSH_AI_TIMEOUT" --connect-timeout 10 \
        https://api.anthropic.com/v1/messages \
        -H @"$header_file" \
        --data "$json_payload" 2>&1)

    rm -f "$header_file"
    
    if [[ $? -ne 0 ]]; then
        _zsh_ai_error "anthropic" "Failed to connect to Anthropic API"
        return 1
    fi
    
    # Debug: Uncomment to see raw response
    # echo "DEBUG: Raw response: $response" >&2

    # Parse response using common parser
    _zsh_ai_parse_response "$response" ".content[0].text" "text"
}