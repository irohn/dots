{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    pam-reattach # Touch ID support in tmux
  ];

  # Hack to make pam-reattach work (fix for tmux sudo touchID)
  environment.etc."pam.d/sudo_local".text = ''
    # Written by nix-darwin
    auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so
    auth       sufficient     pam_tid.so
  '';
}
