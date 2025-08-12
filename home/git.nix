{settings, ...}: {
  programs.git = {
    enable = true;
    userName = settings.username;
    userEmail = settings.email;
    extraConfig = {
      pull = {
        rebase = true;
      };
    };
  };
}
