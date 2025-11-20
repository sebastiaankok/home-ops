{ config, pkgs, ... }:

{

  nix.settings.experimental-features = "nix-command flakes";
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowBroken = true;

  system.stateVersion = 6;

}
