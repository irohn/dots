{
  pkgs,
  config,
  settings,
  ...
}: let
  dev-utils = builtins.fetchGit {
    url = "ssh://git@github.com/greeneyetechnology/dev-utils.git";
    rev = "d2e91560d90633f8999a4a8231a265b2b9313b18";
  };
in {
  home.packages = with pkgs; [
    coreutils
    gawk
    fzf
    fd
    ripgrep
    kubectl
    tailscale
    vault
    azure-cli
  ];

  home.file = {
    ".config/greeneye/bin" = {
      source = "${dev-utils}/bin";
      recursive = true;
    };
    ".config/greeneye/scripts" = {
      source = "${dev-utils}/scripts";
      recursive = true;
    };

    ".config/greeneye/git/config" = {
      text = ''
        [user]
            name = ori
            email = ${settings.work-email}
        [core]
            sshcommand = ssh -i ~/.ssh/greeneye_id_ed25519 -F /dev/null
      '';
    };
  };

  programs.ssh = {
    enable = true;
    includes = ["~/.ssh/greeneye_config"];
  };

  programs.git = {
    enable = true;
    includes = [
      {
        condition = "gitdir:~/projects/greeneye/**";
        path = "~/.config/greeneye/git/config";
      }
    ];
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.config/greeneye/bin"
  ];
}
