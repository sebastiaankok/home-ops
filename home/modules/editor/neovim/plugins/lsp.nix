{ ... }:
{
  programs.nixvim = {
    plugins = {
      helm.enable = true;
      lsp = {
        enable = true;

        keymaps = {
          silent = true;
          diagnostic = {
            # Navigate in diagnostics
            "<leader>k" = "goto_prev";
            "<leader>j" = "goto_next";
          };

          lspBuf = {
            gd = "definition";
            gD = "references";
            gt = "type_definition";
            gi = "implementation";
            K = "hover";
            "<F2>" = "rename";
          };
        };

        servers = {
          ansiblels.enable = true;
          bashls.enable = true;
          cmake.enable = true;
          dockerls.enable = true;
          nixd.enable = true;
          # python
          ruff.enable = true;
          pylsp = {
            enable = true;
            settings = {
              plugins = {
                jedi_completion.fuzzy = true;
              };
            };
          };
          gopls.enable = true;
          terraformls.enable = true;
          helm_ls = {
            enable = true;
            filetypes = ["helm"];
          };
          yamlls = {
            enable = true;
            filetypes = ["yaml"];
            extraOptions = {
              settings = {
                yaml = {
                  schemas = {
                    kubernetes = "{service,deployment,configmap,secret,pod,ingress,role,rolebinding,clusterrole,clusterrolebinding}*.yaml";
                    "https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/argoproj.io/application_v1alpha1.json" = "/*application.yaml";
                    "https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/argoproj.io/applicationset_v1alpha1.json" = "/*applicationset.yaml";
                    "http://json.schemastore.org/github-workflow" = ".github/workflows/*";
                    "http://json.schemastore.org/github-action" = ".github/action.{yml,yaml}";
                    "http://json.schemastore.org/ansible-stable-2.9" = "roles/tasks/*.{yml,yaml}";
                    "http://json.schemastore.org/kustomization" = "kustomization.{yml,yaml}";
                    "http://json.schemastore.org/ansible-playbook" = "*play*.{yml,yaml}";
                    "http://json.schemastore.org/chart" = "Chart.{yml,yaml}";
                    "https://json.schemastore.org/dependabot-v2" = ".github/dependabot.{yml,yaml}";
                    "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json" = "*docker-compose*.{yml,yaml}";
                    "https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json" = "*flow*.{yml,yaml}";

                  };
                  validate = {
                    enable = true;
                  };
                };
              };
            };
          };
          jsonls.enable = true;
          html.enable = true;
          cssls.enable = true;
        };
      };
    };
  };
}
