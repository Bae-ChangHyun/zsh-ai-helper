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
    "max_tokens": 256,
    "temperature": 0.3,
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
        echo "Error: Failed to connect to Anthropic API"
        return 1
    fi
    
    # Debug: Uncomment to see raw response
    # echo "DEBUG: Raw response: $response" >&2
    
    # Extract the content from the response
    # Try using jq if available, otherwise fall back to sed/grep
    if command -v jq &> /dev/null; then
        local result=$(echo "$response" | jq -r '.content[0].text // empty' 2>/dev/null)
        if [[ -z "$result" ]]; then
            # Check for error message
            local error=$(echo "$response" | jq -r '.error.message // empty' 2>/dev/null)
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
        # Commands should be single-line for shell execution
        result=$(echo "$result" | tr -d '\n' | sed 's/[[:space:]]*$//')
        echo "$result"
    else
        # Fallback parsing without jq - handle responses with newlines
        # Use sed to extract the text field, handling potential newlines
        local result=$(echo "$response" | sed -n 's/.*"text":"\([^"]*\)".*/\1/p' | head -1)
        
        # If the simple extraction failed, try a more complex approach for multiline responses
        if [[ -z "$result" ]]; then
            # Extract text field even if it contains escaped newlines
            result=$(echo "$response" | perl -0777 -ne 'print $1 if /"text":"((?:[^"\\]|\\.)*)"/s' 2>/dev/null)
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