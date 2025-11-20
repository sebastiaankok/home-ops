{ config, lib, pkgs, ... }: {
  imports = [
    ./packages.nix
    ./editor/neovim
    ./shell/zsh
    ./shell/bat
    ./shell/atuin
    ./shell/kubeswitch
    ./gui/ghostty
  ];

  # Home-manager defaults
  home.stateVersion = "24.11";

  home.username = "sebastiaan";

  programs = {
    home-manager.enable = true;
    nixvim.enable = true;
  };

  programs.git = {
    enable = true;
    userEmail = "sebastiaan@linux.com";
    userName = "Sebastiaan Kok";
    extraConfig = {
      color = { ui = true; };
      core = { pager = "diff-so-fancy | less --tabs=4 -RF"; };
      interactive = { diffFilter = "diff-so-fancy --patch"; };
    };
  };

  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    matchBlocks."*".setEnv = {
      TERM = "xterm-256color";
    };
  };
}
