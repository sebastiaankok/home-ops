{ config, lib, pkgs, ... }: {
  imports = [
    ./packages.nix
    ./editor/neovim
    ./shell/zsh
    ./shell/bat
    ./shell/atuin
    ./shell/kubeswitch
    ./shell/lazygit
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
      core = {
        pager = "delta";
        excludesfile = "~/.gitignore_global";
      };
      include = {
        path = "~/.config/delta/themes/catppuccin.gitconfig";
      };
      delta = {
        navigate = true;
        dark = true;
        features = "catppuccin-mocha";
      };
      merge = {
        conflictStyle = "zdiff3";
      };
      interactive = { diffFilter = "delta --color-only --syntax-theme='Catppuccin Mocha'"; };
    };
  };

  home.file.".config/delta/themes/catppuccin.gitconfig" = {
    source = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/catppuccin/delta/74b47a345638a2f19b3e5bdb9d7e4984066f9ac7/catppuccin.gitconfig";
      sha256 = "0mdlccyzjzlidiwilbd1fi233v5bmfi1cldj32vnfdqydgd0ln7h";
    };
  };

  home.file.".local/bin/ai-commit" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash

      diff=$(git --no-pager diff --cached)

      curl -s http://localhost:11434/api/chat \
        -H "Content-Type: application/json" \
        -d "$(jq -n \
          --arg diff "$diff" \
          '{
            model: "qwen2.5-coder:3b",
            stream: false,
            format: "json",
            options: { temperature: 0.2 },
            messages: [
              {
                role: "system",
                content: "Generate exactly 3 Git commit message candidates for the given diff. Return JSON only, no markdown fences. Schema: {\"commit_messages\":[\"message1\",\"message2\",\"message3\"]}. Format each message as \"<type>: <short imperative summary>\" using types chore, feat, tests, debug, docs, or ci. Base every message strictly on the lines actually changed in the diff — a line starting with \"-\" is a removal, a line starting with \"+\" is an addition. Never mention docs, tests, or features that are not present in the diff."
              },
              {
                role: "user",
                content: "diff --git a/config.yaml b/config.yaml\n-timeout: 30\n+timeout: 60"
              },
              {
                role: "assistant",
                content: "{\"commit_messages\":[\"chore: increase timeout to 60 seconds\",\"fix: correct timeout value in config\",\"tests: verify updated timeout behavior\"]}"
              },
              {
                role: "user",
                content: "diff --git a/config.yaml b/config.yaml\n-      idle_timeout: \"1h\"\n"
              },
              {
                role: "assistant",
                content: "{\"commit_messages\":[\"chore: remove idle_timeout setting\",\"refactor: drop unused idle_timeout key\",\"debug: verify idle_timeout removal has no side effects\"]}"
              },
              {
                role: "user",
                content: $diff
              }
            ]
          }')" |
        jq -r '.message.content | fromjson | .commit_messages[]' | sed -E 's/^([a-z]+)\([^)]*\)(!?):/\1\2:/'
    '';
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      AddKeysToAgent = "yes";
    };
  };
}
