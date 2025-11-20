{
  programs.ghostty = {
    enable = false;
    settings = {
      theme = "catppuccin-mocha";
      font-size = 10;
      # Disable paste confirmation
      clipboard-paste-protection = false;

      # keybind = [
      #   "ctrl+c=copy"
      #   "ctrl+v=paste"
      #   "ctrl+t=new_tab"
      # ];
    };
  };
}
