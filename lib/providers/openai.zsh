#!/usr/bin/env zsh

# OpenAI API provider for zsh-ai

# Function to call OpenAI API
_zsh_ai_query_openai() {
    local query="$1"
    local response
    
    # Build context
    local context=$(_zsh_ai_build_context)
    local escaped_context=$(_zsh_ai_escape_json "$context")
    local system_prompt=$(_zsh_ai_get_system_prompt "$escaped_context")
    local escaped_system_prompt=$(_zsh_ai_escape_json "$system_prompt")
    
    # Prepare the JSON payload - escape quotes in the query
    local escaped_query=$(_zsh_ai_escape_json "$query")

    # Determine token parameter based on model (newer models use max_completion_tokens)
    local token_param="max_completion_tokens"
    if [[ "$ZSH_AI_OPENAI_MODEL" == gpt-4* ]] || [[ "$ZSH_AI_OPENAI_MODEL" == gpt-3.5* ]]; then
        token_param="max_tokens"
    fi

    local json_payload=$(cat <<EOF
{
    "model": "${ZSH_AI_OPENAI_MODEL}",
    "messages": [
        {
            "role": "system",
            "content": "$escaped_system_prompt"
        },
        {
            "role": "user",
            "content": "$escaped_query"
        }
    ],
    "$token_param": $ZSH_AI_MAX_TOKENS,
    "temperature": $ZSH_AI_TEMPERATURE
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
Authorization: Bearer $OPENAI_API_KEY
content-type: application/json
HEADERS

    response=$(curl -s --max-time "$ZSH_AI_TIMEOUT" --connect-timeout 10 \
        ${ZSH_AI_OPENAI_URL} \
        -H @"$header_file" \
        --data "$json_payload" 2>&1)

    rm -f "$header_file"
    
    if [[ $? -ne 0 ]]; then
        _zsh_ai_error "openai" "Failed to connect to OpenAI API"
        return 1
    fi

    # Debug: Uncomment to see raw response
    # echo "DEBUG: Raw response: $response" >&2

    # Parse response using common parser
    _zsh_ai_parse_response "$response" ".choices[0].message.content" "content"
}