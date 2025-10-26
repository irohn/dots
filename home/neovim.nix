{pkgs, ...}: {
  home.packages = with pkgs; [
    fd
    gcc
    gnumake
    neovim
    nodejs # for copilot
    ripgrep
    tree-sitter
    lazygit
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  home.shellAliases = {
    vim = "nvim";
  };
}
