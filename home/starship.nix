{
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$os$all$character";

      c = {
        format = "[$symbol($version(-$name) )]($style)";
        symbol = " ";
      };

      character = {
        error_symbol = "[\\$](bold red)";
        success_symbol = "[\\$](bold white)";
        vimcmd_symbol = "[](bold blue)";
        vimcmd_visual_symbol = "[](bold orange)";
      };

      cmake = {
        disabled = true;
      };

      directory = {
        format = "[$path]($style)[$read_only]($read_only_style) ";
      };

      gcloud = {
        disabled = true;
      };

      git_branch = {
        format = "[$symbol$branch(:$remote_branch)]($style) ";
        symbol = "";
      };

      golang = {
        format = "[$symbol($version )]($style)";
        symbol = " ";
      };

      hostname = {
        format = "[@$hostname$ssh_symbol](bold green) ";
        ssh_only = false;
        ssh_symbol = "->ssh";
      };

      line_break = {
        disabled = true;
      };

      lua = {
        format = "[$symbol($version )]($style)";
        symbol = "󰢱 ";
      };

      nix_shell = {
        format = "[$symbol$state]($style) ";
        symbol = "❄️ ";
      };

      nodejs = {
        format = "[$symbol($version )]($style)";
        symbol = "󰎙 ";
      };

      os = {
        disabled = false;
        format = " [$symbol](white)";
        symbols = {
          Alpaquita = " ";
          Alpine = " ";
          Amazon = " ";
          Android = " ";
          Arch = " ";
          Artix = " ";
          CentOS = " ";
          Debian = " ";
          DragonFly = " ";
          Emscripten = " ";
          EndeavourOS = " ";
          Fedora = " ";
          FreeBSD = " ";
          Garuda = "󰛓 ";
          Gentoo = " ";
          HardenedBSD = "󰞌 ";
          Illumos = "󰈸 ";
          Linux = " ";
          Mabox = " ";
          Macos = " ";
          Manjaro = " ";
          Mariner = " ";
          MidnightBSD = " ";
          Mint = " ";
          NetBSD = " ";
          NixOS = " ";
          OpenBSD = "󰈺 ";
          OracleLinux = "󰌷 ";
          Pop = " ";
          Raspbian = " ";
          RedHatEnterprise = " ";
          Redhat = " ";
          Redox = "󰀘 ";
          SUSE = " ";
          Solus = "󰠳 ";
          Ubuntu = " ";
          Unknown = " ";
          Windows = "󰍲 ";
          openSUSE = " ";
        };
      };

      python = {
        format = "[$symbol($version )(($virtualenv) )]($style)";
        symbol = "󰌠 ";
      };

      rust = {
        format = "[$symbol($version )]($style)";
        symbol = "󱘗 ";
      };

      username = {
        format = "[$user]($style)";
        show_always = true;
        style_root = "bright-red bold";
        style_user = "bright-green bold";
      };
    };
  };
}
