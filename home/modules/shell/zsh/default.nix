{
  #Add some comments to this file AI!
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
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
    };
    zplug = {
      enable = true;
      plugins = [
        { name = "romkatv/powerlevel10k"; tags = [ as:theme depth:1 ]; } # Installations with additional options. For the list of options, please refer to Zplug README.
        { name = "plugins/git"; tags = [ from:oh-my-zsh ]; }
        { name = "zsh-users/zsh-syntax-highlighting";}
      ];
    };

    plugins = [
      { name = "powerlevel10k-config"; src = ./p10k-config; file = "p10k.zsh"; }
    ];
  };
}
