{nix-darwin, ...}: let
  settings = import ../settings.nix;
  hosts = builtins.listToAttrs (
    builtins.filter (host: builtins.match ".*darwin" host.value.system != null) (
      builtins.map (name: {
        name = name;
        value = settings.hosts.${name};
      }) (builtins.attrNames settings.hosts)
    )
  );
in {
  darwinConfigurations =
    builtins.mapAttrs (
      name: host:
        nix-darwin.lib.darwinSystem {
          system = host.system;
          modules = [../darwin/000-default.nix];
          specialArgs = {
            inherit settings;
            inherit name;
          };
        }
    )
    hosts;
}
