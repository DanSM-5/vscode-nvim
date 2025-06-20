#!/usr/bin/env bash

[[ -v debug ]] && set -x

# Helper for FzfBuffers
# This script caches the bufnrs to delete when fzf terminal window closes

# Current selected buffer in format "[bufnr]"
selected="$1"
# Tempfile that list bufnrs to remove
remove_list="$2"

# Find bufnr inside square brackets
# Need to remove ansi escape codes
bufnr="$(sed 's/\x1b\[[0-9;]*[mGKHF]//g' <<< "$selected" | sed -nE 's|.*\[([0-9]+)\].*|\1|p')"

# Ensure file exist
touch "$remove_list"

# Store selected line for future removal
printf '%s\n' "$bufnr" >> "$remove_list"
