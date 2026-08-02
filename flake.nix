# This part generally remains the same.
{
  description = "NixOS";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      };   
    microvm = {
      url ="github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
     }; 
    };
  outputs = { self, nixpkgs, home-manager, microvm, ... }@inputs: {
    nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        microvm.nixosModules.host
        ./vms/sys-net.nix
      ];
    };
  };
}
