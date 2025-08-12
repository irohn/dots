{
  settings,
  name,
  ...
}: {
  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = settings.hosts."${name}".stateVersion;
  system.defaults.smb.NetBIOSName = "${settings.hosts."${name}".hostname}";

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "${settings.hosts."${name}".system}";
  # Allow unfree packages.
  nixpkgs.config.allowUnfree = true;

  imports = settings.hosts."${name}".imports ++ settings.shared_imports;
}
