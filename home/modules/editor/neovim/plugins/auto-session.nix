{
  programs.nixvim = {
    plugins = {
      auto-session = {
        enable = true;
        settings = {
          enabled = true;
          auto_save = true;
          auto_restore = true;
          auto_create = true;
        };
      };
    };
  };
}
