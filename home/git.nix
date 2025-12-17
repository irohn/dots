{settings, ...}: {
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = settings.username;
        email = settings.email;
      };
      pull = {
        rebase = true;
      };
    };
  };
                 }
