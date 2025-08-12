{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;
    historySubstringSearch = {
      enable = true;
      searchUpKey = [
        "$terminfo[kcuu1]"
        "^[[A"
      ];
      searchDownKey = [
        "$terminfo[kcud1]"
        "^[[B"
      ];
    };
    initContent = ''
      # emacs keybindings
      bindkey -e

      # Edit current command in EDITOR
      autoload -z edit-command-line
      zle -N edit-command-line
      bindkey "^X^E" edit-command-line

      # historySubstringSearch settings
      export HISTORY_SUBSTRING_SEARCH_PREFIXED=true
      export HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=true
    '';
  };
}
