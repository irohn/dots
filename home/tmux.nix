{
  programs.tmux = {
    enable = true;
    extraConfig = ''
      # --- general ---

      set -g default-terminal "screen-256color"
      set-option -ga terminal-overrides ",xterm-256color:Tc"

      set -g extended-keys on

      set -s escape-time 10
      set -sg repeat-time 600
      set -s focus-events on

      # prefix
      set-option -g prefix2 C-Space
      bind C-Space send-prefix -2

      # expect UTF-8 (tmux < 2.2)
      set -q -g status-utf8 on
      setw -q -g utf8 on

      # longer history
      set -g history-limit 5000

      # enable mouse
      set -g mouse on

      # default command
      set -gu default-command "$SHELL"

      # emacs keybindings in command mode (prefix + :)
      set -g status-keys emacs

      # --- display ---

      # start windows numbering at 1
      set -g base-index 1
      # make pane numbering consistent with windows
      setw -g pane-base-index 1

      # rename window to reflect current program
      setw -g automatic-rename on
      # renumber windows when a window is closed
      set -g renumber-windows on

      # set terminal title
      set -g set-titles on

      # activity
      set -g monitor-activity on
      set -g visual-activity off

      # 24h clock
      set-window-option -g clock-mode-style 24

      # increase message display time
      set -g display-time 4000

      # faster status refresh
      set -g status-interval 5

      # --- navigation ---

      # window navigation
      bind-key -n M-l next-window
      bind-key -n M-h previous-window

      # window swap
      bind-key -n M-H swap-window -t -1\; select-window -t -1
      bind-key -n M-L swap-window -t +1\; select-window -t +1

      # window jump
      bind-key -n M-1 select-window -t 1
      bind-key -n M-2 select-window -t 2
      bind-key -n M-3 select-window -t 3
      bind-key -n M-4 select-window -t 4
      bind-key -n M-5 select-window -t 5
      bind-key -n M-6 select-window -t 6
      bind-key -n M-7 select-window -t 7
      bind-key -n M-8 select-window -t 8
      bind-key -n M-9 select-window -t 9

      # pane navigation
      bind -r h select-pane -L
      bind -r j select-pane -D
      bind -r k select-pane -U
      bind -r l select-pane -R

      # pane resizing
      bind -r H resize-pane -L 2
      bind -r J resize-pane -D 2
      bind -r K resize-pane -U 2
      bind -r L resize-pane -R 2

      # pane swap
      bind > swap-pane -D
      bind < swap-pane -U

      # tmux ssh https://github.com/irohn/xdg/blob/master/config/tmux/tssh.sh
      unbind t
      bind-key -r t run-shell "tmux neww ~/.config/tmux/tssh.sh"

      # sessionizer https://github.com/irohn/xdg/blob/master/config/tmux/sessionizer.sh
      bind-key -r f run-shell "tmux neww ~/.config/tmux/sessionizer.sh"

      # join/break last/current-used pane into/out-of current window
      bind-key @ join-pane -h -s !
      bind-key ! break-pane

      # --- actions ---

      # synchronize all panes in a window (multi-exec)
      unbind m
      bind m set-window-option synchronize-panes

      # source tmux config file
      bind R source-file "~/projects/personal/xdg/config/tmux/tmux.conf" \; \
      display-message "Configuration reloaded successfully!"

      # --- context menu (right click) ---

      bind-key -T root MouseDown3Pane display-menu -O -T "#[align=centre]" -x M -y M \
        "Horizontal Split" h "split-window -h" \
        "Vertical Split" v "split-window -v" \
        "" \
        "#{?#{>:#{window_panes},1},#{?window_zoomed_flag,Unzoom,Zoom},}" z "#{?#{>:#{window_panes},1},resize-pane -Z,}" \
        "#{?#{&&:#{>:#{window_panes},1},#{!=:#{window_zoomed_flag},1}},#{?pane_synchronized,Unsynchronize,Synchronize} Panes,}" s "#{?#{&&:#{>:#{window_panes},1},#{!=:#{window_zoomed_flag},1}},set-window-option synchronize-panes,}" \
        "" \
        "#{?pane_at_top,,Swap Up}" u "#{?pane_at_top,,swap-pane -U}" \
        "#{?pane_at_bottom,,Swap Down}" d "#{?pane_at_bottom,,swap-pane -D}" \
        "#{?pane_at_left,,Swap Left}" h "#{?pane_at_left,,swap-pane -L}" \
        "#{?pane_at_right,,Swap Right}" l "#{?pane_at_right,,swap-pane -R}" \
        "" \
        "New SSH Window" S "run-shell 'tmux neww ~/.config/tmux/tssh.sh'" \
        "Sessionizer" F "run-shell 'tmux neww ~/.config/tmux/sessionizer.sh'" \
        "" \
        "Close Pane" x "kill-pane" \
        "Detach Session" q "detach-client"

      bind-key -T root MouseDown3Status display-menu -O -T "#[align=centre]" -x M -y M \
        "New Window" n "new-window" \
        "" \
        "Swap Left" h "swap-window -t:-1" \
        "Swap Right" l "swap-window -t:+1" \
        "" \
        "New SSH Window" S "run-shell 'tmux neww ~/.config/tmux/tssh.sh'" \
        "Sessionizer" F "run-shell 'tmux neww ~/.config/tmux/sessionizer.sh'" \
        "" \
        "Close Window" x "kill-window" \
        "Detach Session" q "detach-client"

      # --- appearance ---

      # status-bar position
      set-option -g status-position top

      run-shell "~/.config/tmux/colorizer.sh --cache"

      # Toggle between light and dark themes
      unbind T
      bind-key -r T run-shell "tmux display-popup -E ~/.config/tmux/colorizer.sh"

      # Default statusbar color
      set-option -g status-style bg="#{@base00}",fg="#{@base05}"

      # Set active pane border color
      set-option -g pane-active-border-style fg="#{@base07}"

      # Set inactive pane border color
      set-option -g pane-border-style fg="#{@base02}"

      # Message info
      set-option -g message-style bg="#{@base00}",fg="#{@base07}"

      set-window-option -g window-status-separator ""

      set-option -g status-left ""

      set-option -g status-right "\
      #{?window_zoomed_flag,#[bg=#{@base09}] ZOOM ,}\
      #{?pane_synchronized,#[bg=#{@base0F}] SYNC ,}\
      #[bg=#{@base01}, fg=#{@base07}]#{?client_prefix,#[bg=#{@base0E}],} #S \
      #[bg=#{@base02}, fg=#{@base05}] %H:%M "

      set-window-option -g window-status-current-format "\
      #[bg=#{@base03}, fg=#{@base00}] #I:#W "

      set-window-option -g window-status-format "\
      #[bg=#{@base02},fg=#{@base05},noitalics] #I:#W "

      set-option -g status-justify left
    '';
  };

  # Create the necessary script files
  home.file = {
    ".config/tmux/tssh.sh" = {
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail

        SSH_CONFIG="$HOME/.ssh/config"

        get_hosts() {
            local config_file="$1"
            [ -f "$config_file" ] || return 0

            while IFS= read -r line; do
                # Skip comments and empty lines
                [[ "$line" =~ ^[[:space:]]*# ]] && continue
                [[ "$line" =~ ^[[:space:]]*$ ]] && continue

                # Handle Include directives
                if [[ "$line" =~ ^[[:space:]]*Include[[:space:]]+(.*) ]]; then
                    include_path="''${BASH_REMATCH[1]}"
                    # Expand path if it starts with ~
                    include_path="''${include_path/#\~/$HOME}"
                    # Handle wildcards in include path
                    for included_file in $include_path; do
                        [ -f "$included_file" ] && get_hosts "$included_file"
                    done
                    continue
                fi

                # Extract Host entries
                if [[ "$line" =~ ^[[:space:]]*Host[[:space:]]+(.*) ]]; then
                    host_pattern="''${BASH_REMATCH[1]}"
                    # Skip wildcard-only patterns
                    [[ "$host_pattern" != "*" ]] && echo "$host_pattern"
                fi
            done <"$config_file"
        }

        selected_hosts=$(get_hosts "$SSH_CONFIG" | sort | fzf --layout=reverse -m --bind ctrl-a:select-all)

        if [ -z "''${TMUX:-}" ]; then
            echo "error: not in a tmux session."
            exit 1
        fi

        tmux_session_name=$(tmux display-message -p '#S')
        tmux new-window -t "$tmux_session_name" -n gssh
        tmux_session_id=$(tmux display-message -p '#I')

        host_count=$(echo "$selected_hosts" | wc -w)
        for ((i = 1; i < host_count; i++)); do
            tmux split-window -t "$tmux_session_name":"$tmux_session_id"
            tmux select-layout tiled
        done

        i=1
        for host in $selected_hosts; do
            tmux send-keys -t "$i" "clear && ssh '$host'" Enter
            ((i += 1))
        done
      '';
      executable = true;
    };

    ".config/tmux/sessionizer.sh" = {
      text = ''
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
            find_command="fd '^.git$' $FIND_DIR $(printf -- "--exclude %s " "''${excludes[@]}") --hidden --type=directory --no-ignore --max-depth ''${FIND_DEPTH} -x echo {//}"
        else
            find_command="find $FIND_DIR -maxdepth ''${FIND_DEPTH} -name .git -type d $(printf -- "-not -path '*/%s/*' " "''${excludes[@]}" | sed 's/ $//') -exec dirname {} \;"
        fi

        paths=$(bash -c "$find_command")
        for include in "''${includes[@]}"; do
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
      '';
      executable = true;
    };

    ".config/tmux/colorizer.sh" = {
      text = ''
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

        if [ "''${1:-}" == "--cache" ]; then
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
      '';
      executable = true;
    };

    ".config/tmux/colors/tomorrow-night.conf" = {
      text = ''
        # Base16 Tomorrow Night
        # Author: Chris Kempson (http://chriskempson.com)

        set -g @base00 "#1d1f21"
        set -g @base01 "#282a2e"
        set -g @base02 "#373b41"
        set -g @base03 "#969896"
        set -g @base04 "#b4b7b4"
        set -g @base05 "#c5c8c6"
        set -g @base06 "#e0e0e0"
        set -g @base07 "#ffffff"
        set -g @base08 "#cc6666"
        set -g @base09 "#de935f"
        set -g @base0A "#f0c674"
        set -g @base0B "#b5bd68"
        set -g @base0C "#8abeb7"
        set -g @base0D "#81a2be"
        set -g @base0E "#b294bb"
        set -g @base0F "#a3685a"
      '';
    };

    ".config/tmux/colors/tokyonight-storm.conf" = {
      text = ''
        # Tokyo Night Storm
        # Author: Folke Lemaitre

        set -g @base00 "#24283b"
        set -g @base01 "#1f2335"
        set -g @base02 "#292e42"
        set -g @base03 "#565f89"
        set -g @base04 "#737aa2"
        set -g @base05 "#c0caf5"
        set -g @base06 "#c0caf5"
        set -g @base07 "#c0caf5"
        set -g @base08 "#f7768e"
        set -g @base09 "#ff9e64"
        set -g @base0A "#e0af68"
        set -g @base0B "#9ece6a"
        set -g @base0C "#7dcfff"
        set -g @base0D "#7aa2f7"
        set -g @base0E "#bb9af7"
        set -g @base0F "#f7768e"
      '';
    };

    ".config/tmux/colors/tokyonight-moon.conf" = {
      text = ''
        # Tokyo Night Moon
        # Author: Folke Lemaitre

        set -g @base00 "#222436"
        set -g @base01 "#1e2030"
        set -g @base02 "#2d3149"
        set -g @base03 "#544a65"
        set -g @base04 "#737aa2"
        set -g @base05 "#c8d3f5"
        set -g @base06 "#c8d3f5"
        set -g @base07 "#c8d3f5"
        set -g @base08 "#ff757f"
        set -g @base09 "#ff966c"
        set -g @base0A "#ffc777"
        set -g @base0B "#c3e88d"
        set -g @base0C "#86e1fc"
        set -g @base0D "#82aaff"
        set -g @base0E "#c099ff"
        set -g @base0F "#ff757f"
      '';
    };

    ".config/tmux/colors/tokyonight-night.conf" = {
      text = ''
        # Tokyo Night Night
        # Author: Folke Lemaitre

        set -g @base00 "#1a1b26"
        set -g @base01 "#16161e"
        set -g @base02 "#2f3549"
        set -g @base03 "#444b6a"
        set -g @base04 "#787c99"
        set -g @base05 "#c0caf5"
        set -g @base06 "#c0caf5"
        set -g @base07 "#c0caf5"
        set -g @base08 "#f7768e"
        set -g @base09 "#ff9e64"
        set -g @base0A "#e0af68"
        set -g @base0B "#9ece6a"
        set -g @base0C "#7dcfff"
        set -g @base0D "#7aa2f7"
        set -g @base0E "#bb9af7"
        set -g @base0F "#f7768e"
      '';
    };

    ".config/tmux/colors/tokyonight-dawn.conf" = {
      text = ''
        # Tokyo Night Dawn
        # Author: Folke Lemaitre

        set -g @base00 "#e1d8e3"
        set -g @base01 "#f7f7f7"
        set -g @base02 "#d6d6d6"
        set -g @base03 "#9699a3"
        set -g @base04 "#6e7681"
        set -g @base05 "#3760bf"
        set -g @base06 "#3760bf"
        set -g @base07 "#3760bf"
        set -g @base08 "#f52a65"
        set -g @base09 "#b15c00"
        set -g @base0A "#8c6c3e"
        set -g @base0B "#587539"
        set -g @base0C "#007197"
        set -g @base0D "#2e7de9"
        set -g @base0E "#9854f1"
        set -g @base0F "#f52a65"
      '';
    };

    ".config/tmux/colors/kanagawa-wave.conf" = {
      text = ''
        # Kanagawa Wave
        # Author: rebelot

        set -g @base00 "#1f1f28"
        set -g @base01 "#16161d"
        set -g @base02 "#223249"
        set -g @base03 "#54546d"
        set -g @base04 "#727169"
        set -g @base05 "#dcd7ba"
        set -g @base06 "#c8c093"
        set -g @base07 "#717c7c"
        set -g @base08 "#c34043"
        set -g @base09 "#ffa066"
        set -g @base0A "#c0a36e"
        set -g @base0B "#76946a"
        set -g @base0C "#6a9589"
        set -g @base0D "#7e9cd8"
        set -g @base0E "#957fb8"
        set -g @base0F "#d27e99"
      '';
    };

    ".config/tmux/colors/kanagawa-dragon.conf" = {
      text = ''
        # Kanagawa Dragon
        # Author: rebelot

        set -g @base00 "#181616"
        set -g @base01 "#0d0c0c"
        set -g @base02 "#393836"
        set -g @base03 "#625e5a"
        set -g @base04 "#a6a69c"
        set -g @base05 "#c5c9c5"
        set -g @base06 "#b6927b"
        set -g @base07 "#c4b28a"
        set -g @base08 "#c4746e"
        set -g @base09 "#b6927b"
        set -g @base0A "#c4b28a"
        set -g @base0B "#8a9a7b"
        set -g @base0C "#8ba4b0"
        set -g @base0D "#8ba4b0"
        set -g @base0E "#a292a3"
        set -g @base0F "#b98d7b"
      '';
    };

    ".config/tmux/colors/kanagawa-lotus.conf" = {
      text = ''
        # Kanagawa Lotus
        # Author: rebelot

        set -g @base00 "#f2ecbc"
        set -g @base01 "#e7dba0"
        set -g @base02 "#e4d794"
        set -g @base03 "#b8b5a6"
        set -g @base04 "#a6a69c"
        set -g @base05 "#545464"
        set -g @base06 "#43436c"
        set -g @base07 "#282727"
        set -g @base08 "#c84053"
        set -g @base09 "#cc6d00"
        set -g @base0A "#836f4a"
        set -g @base0B "#6f894e"
        set -g @base0C "#6693bf"
        set -g @base0D "#6693bf"
        set -g @base0E "#b35b79"
        set -g @base0F "#b35b79"
      '';
    };
  };

  programs.zsh.initContent = ''if [ -z "$TMUX" ]; then tmux -u new-session -A -s default; fi '';
}
