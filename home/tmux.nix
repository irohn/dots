{
  programs.tmux = {
    enable = true;
  };

  # Start tmux automatically if not already running
  programs.zsh.initContent = ''if [ -z "$TMUX" ]; then tmux -u new-session -A -s default; fi '';
}
