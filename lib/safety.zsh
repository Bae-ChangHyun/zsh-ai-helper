#!/usr/bin/env zsh

# Safety checks for dangerous commands

# Array of dangerous command patterns
# Each entry: "pattern|warning_message"
typeset -a _ZSH_AI_DANGEROUS_PATTERNS
_ZSH_AI_DANGEROUS_PATTERNS=(
    # Destructive rm commands
    'rm -rf /|This may delete ALL files on your system'
    'rm -rf /*|This may delete ALL files on your system'
    'rm -rf ~|This may delete ALL files in your home directory'
    'rm -rf ~/*|This may delete ALL files in your home directory'
    'sudo rm -rf|Dangerous recursive deletion with root privileges'

    # dd commands (can destroy disks)
    'dd if=.*of=/dev/sd|This may overwrite an entire disk'
    'dd if=.*of=/dev/hd|This may overwrite an entire disk'
    'dd if=.*of=/dev/nvme|This may overwrite an entire disk'
    'dd of=/dev/sd|This may overwrite an entire disk'
    'dd of=/dev/hd|This may overwrite an entire disk'
    'dd of=/dev/nvme|This may overwrite an entire disk'
    'sudo dd|Disk operations with root privileges'

    # Filesystem formatting
    'mkfs\.|This will format/erase a partition'
    'mkfs |This will format/erase a partition'
    'sudo mkfs|This will format/erase a partition with root privileges'

    # Dangerous chmod
    'chmod -R 777|This makes all files world-writable (security risk)'
    'chmod 777|This makes files world-writable (security risk)'
    'chmod -R 000|This may make files inaccessible'

    # Output redirection to devices
    '> /dev/sd|This may corrupt a disk'
    '>> /dev/sd|This may corrupt a disk'
    '> /dev/hd|This may corrupt a disk'
    '>> /dev/hd|This may corrupt a disk'
    '> /dev/nvme|This may corrupt a disk'
    '>> /dev/nvme|This may corrupt a disk'

    # Fork bomb
    ':\(\)\{:\|:&\};:|This is a fork bomb that can crash your system'

    # Dangerous wget/curl to bash
    'curl.*\| *bash|Piping internet content directly to bash is dangerous'
    'curl.*\| *sh|Piping internet content directly to sh is dangerous'
    'wget.*\| *bash|Piping internet content directly to bash is dangerous'
    'wget.*\| *sh|Piping internet content directly to sh is dangerous'

    # Move to /dev/null
    'mv .* /dev/null|Moving files to /dev/null deletes them permanently'

    # Overwrite important system files
    '> /etc/|Overwriting system configuration files'
    '> /boot/|Overwriting boot files may prevent system startup'

    # Dangerous find with exec
    'find.*-exec rm|Mass file deletion'
    'find.*-delete|Mass file deletion'

    # Force kill commands
    'kill -9|Forces process termination without cleanup (use kill -15 first)'
    'killall -9|Forces multiple process termination without cleanup'
)

# Function to check if a command contains dangerous patterns
# Returns: 0 if safe, 1 if dangerous (sets _ZSH_AI_DANGER_WARNING)
_zsh_ai_check_dangerous_command() {
    local cmd="$1"
    _ZSH_AI_DANGER_WARNING=""

    # Skip empty commands
    [[ -z "$cmd" ]] && return 0

    # Check against each dangerous pattern
    for entry in "${_ZSH_AI_DANGEROUS_PATTERNS[@]}"; do
        local pattern="${entry%%|*}"
        local message="${entry##*|}"

        # Use grep for regex matching
        if echo "$cmd" | grep -qE "$pattern" 2>/dev/null; then
            _ZSH_AI_DANGER_WARNING="$message"
            return 1
        fi
    done

    return 0
}

# Function to add warning comment to dangerous command
# Usage: _zsh_ai_add_warning_comment "command" "warning_message"
_zsh_ai_add_warning_comment() {
    local cmd="$1"
    local warning="$2"

    # Format: command  # [WARNING] message
    echo "$cmd  # [WARNING] $warning"
}
