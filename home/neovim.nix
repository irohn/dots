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

    lua-language-server
    stylua

    nixd
    alejandra

    basedpyright

    ansible-language-server

    bash-language-server

    cmake-language-server

    vscode-langservers-extracted

    docker-language-server
    earthlyls
    helm-ls

    gopls
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  home.shellAliases = {
    vim = "nvim";
  };
}
