{
  programs.nixvim = {
    plugins = {
      avante = {
        enable = false;
        settings = {
          prompt_logger = {
            enabled = true;
          };

          mappings = {
            ask = "<leader>aa"; # Ask AI about code
            edit = "<leader>ae"; # Edit with AI
            refresh = "<leader>ar"; # Refresh AI suggestions
            diff = {
              ours = "co";
              theirs = "ct";
              none = "c0";
              both = "cb";
              next = "]x";
              prev = "[x";
            };
            suggestion = {
              accept = "<C-l>"; # Ctrl+l
              next = "<C-n>"; # Ctrl+n
              prev = "<C-p>"; # Ctrl+p
              dismiss = "<C-]>"; # Keep Ctrl+]
            };
          };
          behaviour = {
            auto_suggestions = false; # Disable auto-suggestions if preferred
            enable_token_counting = true;
            auto_approve_tool_permissions = false;
          };
          windows = {
            width = 30; # Sidebar width
            wrap = true; # Enable text wrapping
            sidebar_header = {
              align = "center";
              rounded = true;
            };
          };
          highlights = {
            diff = {
              current = "DiffText";
              incoming = "DiffAdd";
            };
          };
          diff = {
            autojump = true;
            debug = false;
            list_opener = "copen";
          };
          hints = { enabled = true; };
        };
      };
    };
  };
}
