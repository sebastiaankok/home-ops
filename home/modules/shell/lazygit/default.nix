{
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        theme = {
          activeBorderColor = [ "#89b4fa" "bold" ];
          inactiveBorderColor = [ "#a6adc8" ];
          searchingActiveBorderColor = [ "#f9e2af" ];
          optionsTextColor = [ "#89b4fa" ];
          selectedLineBgColor = [ "#313244" ];
          inactiveViewSelectedLineBgColor = [ "#6c7086" ];
          cherryPickedCommitFgColor = [ "#89b4fa" ];
          cherryPickedCommitBgColor = [ "#45475a" ];
          markedBaseCommitFgColor = [ "#89b4fa" ];
          markedBaseCommitBgColor = [ "#f9e2af" ];
          unstagedChangesColor = [ "#f38ba8" ];
          defaultFgColor = [ "#cdd6f4" ];
        };
      };

      authorColors = {
        "*" = "#b4befe";
      };
      git = {
        pagers = [
          { pager = "delta --dark --paging=never --syntax-theme=\"Catppuccin Mocha\""; }
          { pager = "delta --dark --paging=never --side-by-side --syntax-theme=\"Catppuccin Mocha\""; }
        ];
      };
    };
  };

  programs.lazygit.settings.customCommands = [
    {
      key = "<c-a>";
      description = "Generate AI commit message";
      context = "files";
      command = "git commit -m \"{{.Form.Msg}}\"";
      prompts = [
        {
          type = "menuFromCommand";
          title = "AI commits";
          key = "Msg";
          command = "ai-commit";
          filter = "^(?P<raw>.+)$";
          valueFormat = "{{ .raw }}";
          labelFormat = "{{ .raw | green }}";
        }
      ];
    }
  ];
}

