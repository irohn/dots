{
  nixpkgs,
  home-manager,
  agenix,
  flake-utils,
  neovim-nightly-overlay,
  ...
}: let
  settings = import ../settings.nix;
in {
  homeConfigurations = builtins.listToAttrs (
    map (system: {
      name = system;
      value = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            neovim-nightly-overlay.overlays.default
          ];
        };
        modules = [
          agenix.homeManagerModules.default
          ../home/000-default.nix
        ];
        extraSpecialArgs = {
          inherit
            settings
            ;
        };
      };
    })
    flake-utils.lib.defaultSystems
  );
}
