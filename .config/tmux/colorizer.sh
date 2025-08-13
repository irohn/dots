#!/usr/bin/env bash
set -euo pipefail

COLORS_PATH="$HOME/.config/tmux/colors"
DEFAULT_COLORSCHEME="tomorrow-night"
CACHE_FILE="$HOME/.cache/tmux_colorscheme"

load_from_cache() {
    if [ -f "$CACHE_FILE" ]; then
        tmux source-file "$(cat "$CACHE_FILE")"
        exit 0
    else
        tmux source-file "$HOME/.config/tmux/colors/$DEFAULT_COLORSCHEME.conf"
        exit 0
    fi
}

if [ "${1:-}" == "--cache" ]; then
    load_from_cache
fi

if command -v "fd" >/dev/null 2>&1; then
    find_command="fd .conf \"$COLORS_PATH\""
else
    find_command="find \"$COLORS_PATH\" -name '*.conf'"
fi

colorschemes=$(bash -c "$find_command" | xargs -n 1 basename)
selection=$(echo "$colorschemes" | fzf --height=60% --layout=reverse)
selection_file="$COLORS_PATH/$selection"

tmux source-file "$selection_file"

echo "$selection_file" >"$CACHE_FILE"
