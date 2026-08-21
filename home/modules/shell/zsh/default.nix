{ pkgs, lib, ... }:
{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;

    initContent = lib.mkBefore ''
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi

      source ${pkgs.oh-my-zsh}/share/oh-my-zsh/plugins/git/git.plugin.zsh
    '';

    completionInit = ''
      fpath=(${pkgs.zsh}/share/zsh/${pkgs.zsh.version}/functions $fpath)

      autoload -Uz compinit
      if [[ -n $HOME/.zcompdump(#qNmh+1) ]]; then
        compinit
      else
        compinit -C
      fi
    '';

    syntaxHighlighting.enable = true;

    plugins = [
      { name = "powerlevel10k"; src = pkgs.zsh-powerlevel10k; file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme"; }
      { name = "powerlevel10k-config"; src = ./p10k-config; file = "p10k.zsh"; }
    ];

    shellAliases = {
      k = "kubecolor";
      up = "sudo darwin-rebuild switch --flake path:$HOME/projects/home-ops ; source ~/.zshrc";
      kx = "switch";
      ld = "eza -lD --icons=always" ;
      ll = "eza -l --group-directories-first --icons=always";
      ls = "eza -l --group-directories-first --icons=always";
      lS = "eza -lF --color=always --sort=size --icons=always | grep -v /";
      lt = "eza -l --sort=modified --icons=always";
      lg = "lazygit";
      cat = "bat -pp";
      sm = "bash $HOME/projects/toolbox/llm/select_openrouter_model.sh; source ~/.zshrc";
      ask = "aider --chat-mode ask";
      aider = "bash $HOME/projects/toolbox/llm/aider_wrapper.sh";
      sync = "rclone sync k3s-home:/data ~/backups/k3s-home --exclude 'library/**' --exclude 'home-assistant/.venv/**' --exclude 'home-assistant/home-assistant.log*' --exclude 'frigate/frigate/**' --exclude 'mediaserver/jellyseerr/cache/**'  --exclude 'mediaserver/jellyseerr/images/**' --exclude 'mediaserver/jellyfin/metadata/**' --exclude 'navidrome/cache' --retries 3 --low-level-retries 10 --size-only --progress --links --transfers 16 --checkers 128";
      vi = "nvim";
      vim = "nvim";
      diff = "colordiff -Naur";
      vimdiff = "nvim -d";
      ki ="kubectl get pods -o 'custom-columns=NAME:.metadata.name,IMAGES:.spec.containers[*].image'";
    };
  };
}
