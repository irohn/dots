{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = ["~/.ssh/greeneye_config" "~/.ssh/irohn_config"];
  };
}
