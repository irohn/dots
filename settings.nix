{
  username = "ori";
  email = "orisneh@gmail.com";
  work-email = "orisne@greeneye.ag";
  home = {
    imports = [
      ./home/age.nix
      ./home/alacritty.nix
      ./home/bitwarden.nix
      ./home/direnv.nix
      ./home/eza.nix
      ./home/fd.nix
      ./home/fzf.nix
      # ./home/ghostty.nix # marked broken on MacOS
      ./home/git.nix
      ./home/greeneye.nix
      ./home/k8s.nix
      ./home/librewolf.nix
      ./home/neovim.nix
      ./home/ripgrep.nix
      ./home/starship.nix
      ./home/tmux.nix
      ./home/zoxide.nix
      ./home/zsh.nix
    ];
  };
  hosts = {
    macbook = {
      hostname = "macbook";
      system = "aarch64-darwin";
      stateVersion = 5;
      imports = [
        ./darwin/aerospace.nix
        ./darwin/fonts.nix
        ./darwin/homebrew.nix
        ./darwin/networking.nix
        ./darwin/security.nix
        ./darwin/system.nix
        ./darwin/users.nix
      ];
    };
    desktop = {
      hostname = "desktop";
      system = "x86_64-linux";
      stateVersion = "24.11";
    };
  };
  shared_imports = [];
}
