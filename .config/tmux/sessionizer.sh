#!/usr/bin/env bash
set -euo pipefail

FIND_DEPTH=5
FIND_DIR="$HOME"

excludes=(
    .local
    .cargo
    .cache
    .npm
    node_modules
    .virtualenvs
    venv
    .venv
    __pycache__
    .pytest_cache
    .mypy_cache
    .pyenv
    target
    dist
    build
    out
)

includes=(
    ~/.config/nvim
    ~/.config/git
    ~/.ssh
)

if command -v "fd" >/dev/null 2>&1; then
    find_command="fd '^.git$' $FIND_DIR $(printf -- "--exclude %s " "${excludes[@]}") --hidden --type=directory --no-ignore --max-depth ${FIND_DEPTH} -x echo {//}"
else
    find_command="find $FIND_DIR -maxdepth ${FIND_DEPTH} -name .git -type d $(printf -- "-not -path '*/%s/*' " "${excludes[@]}" | sed 's/ $//') -exec dirname {} \;"
fi

paths=$(bash -c "$find_command")
for include in "${includes[@]}"; do
    paths="$paths"$'\n'"$include"
done

if command -v "fzf" >/dev/null 2>&1; then
    selected_dir=$(echo "$paths" | fzf --height=60% --layout=reverse --preview-window 'right,border-left' --preview 'ls {}')
else
    read -rp "Sessionize Directory: " dir_input
    selected_dir=$(echo "$paths" | grep "$dir_input" | head -1)
fi

session_name=$(basename "$selected_dir" | tr . _)
if ! tmux has-session -t="$session_name" 2>/dev/null; then
    tmux new-session -ds "$session_name" -c "$selected_dir"
fi
([ -z "$TMUX" ] && tmux attach -t "$session_name") || tmux switch-client -t "$session_name"
