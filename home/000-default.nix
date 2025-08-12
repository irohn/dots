{
  pkgs,
  lib,
  settings,
  neovim-nightly-overlay,
  ...
}: {
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = settings.username;
  home.homeDirectory =
    if pkgs.stdenv.isDarwin
    then "/Users/${settings.username}"
    else "/home/${settings.username}";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05"; # Please read the comment before changing.

  home.packages = with pkgs; [
    unixtools.watch
    fd
    ripgrep
  ];

  # Allow unfree packages.
  nixpkgs.config.allowUnfree = true;

  home.sessionVariables = lib.mkIf pkgs.stdenv.isDarwin {
    XDG_RUNTIME_DIR = "$(getconf DARWIN_USER_TEMP_DIR)";
  };

  imports = settings.home.imports or [];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
