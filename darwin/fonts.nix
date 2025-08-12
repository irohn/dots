{pkgs, ...}: {
  fonts = {
    packages = with pkgs; [
      nerd-fonts._0xproto
      nerd-fonts.jetbrains-mono
    ];
  };
}
