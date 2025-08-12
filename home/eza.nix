{
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "auto";
    extraOptions = [
      "--color-scale"
      "--group-directories-first"
    ];
  };

  home.shellAliases = {
    ls = "eza";
    ll = "eza -lAh";
    la = "eza -laa";
    lt = "eza --almost-all --tree --color=auto --icons=auto --git-ignore --smart-group --mounts --level=5";
  };
}
