{
  inputs = {
    # This is pointing to an unstable release.
    # If you prefer a stable release instead, you can change the word unstable to the latest number shown here: https://nixos.org/download
    # i.e. nixos-24.11
    # Use `nix flake update` to update the flake to the latest revision of the chosen release channel.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wg-namespace = {
      url = "github:aisair/wg-namespace-flake";
    };
  };
  outputs = inputs@{ self, nixpkgs, agenix, wg-namespace, ... }: {
    # Configuration for host "curren"
    nixosConfigurations.curren = nixpkgs.lib.nixosSystem {
      modules = [
        ./configuration.nix

        agenix.nixosModules.default
        {
          environment.systemPackages = [ agenix.packages.x86_64-linux.default ];
        }

        wg-namespace.nixosModules.default
      ];
    };
  };
}

