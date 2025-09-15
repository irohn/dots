{
  homebrew = {
    enable = true;
    # 'zap': uninstalls all formulae(and related files) not listed here.
    onActivation.cleanup = "zap";
    taps = [];
    brews = [];
    casks = [
      "alt-tab"
      "bazecor"
      "docker-desktop"
      "karabiner-elements"
      "keepingyouawake" # Prevent screen from turning off
      "scroll-reverser"
      "logi-options+"
      "raycast"
      "slack"
      "stremio"
      "tailscale-app"
      "xquartz"
    ];
  };
}
