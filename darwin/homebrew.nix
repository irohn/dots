{
  homebrew = {
    enable = true;
    # 'zap': uninstalls all formulae(and related files) not listed here.
    # onActivation.cleanup = "zap";
    taps = [];
    brews = [];
    casks = [
      "alt-tab"
      "docker-desktop"
      "k3d"
      "karabiner-elements"
      "keepingyouawake" # Prevent screen from turning off
      "scroll-reverser"
      "raycast"
      "slack"
      "ollama-app"
      "stremio"
      "tailscale-app"
      "xquartz"
      "discord"
    ];
  };
}
