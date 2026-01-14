{pkgs, ...}: {
  home.packages = with pkgs; [
    fd
    gcc
    gnumake
    neovim
    ripgrep
    tree-sitter
    lazygit
    nodejs # for copilot
    go # for gopls
    cargo # for rust-analyzer
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  home.shellAliases = {
    vim = "nvim";
  };
}
