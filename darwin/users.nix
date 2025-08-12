{settings, ...}: {
  users.users = {
    "${settings.username}" = {
      home = "/Users/${settings.username}";
      description = "User ${settings.username}";
    };
  };

  nix.settings.trusted-users = [
    settings.username
  ];
  system.primaryUser = "${settings.username}";
}
