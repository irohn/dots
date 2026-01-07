{
  pkgs,
  pkgs-stable,
  config,
  settings,
  ...
}: let
  dev-utils = builtins.fetchGit {
    url = "ssh://git@github.com/greeneyetechnology/dev-utils.git";
    rev = "ac82d6f751e275a0e40cc81fcb173f0af20cc19b";
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
    ] ++ [
    pkgs-stable.azure-cli
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
    includes = ["~/.ssh/greeneye_config"];
  };

  programs.git = {
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
