{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.wyrdgard; let
  cfg = config.wyrdgard.apps.cli-apps.nixvim;
in {
  options.wyrdgard.apps.cli-apps.nixvim = with types; {
    enable = mkBoolOpt true "Whether to enable nixvim or not (Default true)";
  };

  config = mkIf cfg.enable {
    programs.nixvim = {
      enable = true;
      colorschemes.tokyonight = enabled;
      globals.mapleader = " ";

      clipboard.providers.wl-copy = enabled;

      options = {
        number = true;
        relativenumber = true;
        shiftwidth = 2;
      };

      keymaps = [
        {
          action = "<cmd>Ex<CR>";
          key = "<leader>e";
          options.desc = "Open Explorer";
        }
        {
          mode = "n";
          action = "<cmd>w<CR>";
          key = "<C-s>";
          options.desc = "Save";
        }
        {
          mode = "n";
          action = "<cmd>noh<CR>";
          key = "<esc>";
          options.silent = true;
        }
        {
          mode = "n";
          action = "<cmd>UndotreeToggle<CR>";
          key = "<leader>ut";
          options.desc = "Toggle Undotree";
        }
        {
          mode = "n";
          action = "<cmd>UndotreeToggle<CR>";
          key = "<leader>uf";
          options.desc = "Focus Undotree";
        }
      ];

      plugins = {
        telescope = {
          enable = true;
          keymaps = {
            "<leader>sr" = {
              action = "oldfiles";
              desc = "[s]earch [r]ecent";
            };

            "<leader>sk" = {
              action = "keymaps";
              desc = "[s]earch [k]eys";
            };

            "<leader>sg" = {
              action = "live_grep";
              desc = "[s]earch [g]rep";
            };
          };
        };

	harpoon = {
        enable = true;
        enableTelescope = true;
        keymaps = {
          addFile = "<leader>a";
          toggleQuickMenu = "<leader>ha";
          navFile = {
            "1" = "<C-1>";
            "2" = "<C-2>";
            "3" = "<C-3>";
            "4" = "<C-4>";
          };
        };
      };

        treesitter = {
          enable = true;
        };

        luasnip.enable = true;

        lualine.enable = true;

        lsp = {
          enable = true;

          servers = {
            nixd.enable = true;
          };
          keymaps = {
            lspBuf = {
              "<leader>K" = "hover";
              "<leader>gf" = "references";
              "<leader>gd" = "definition";
              "<leader>gi" = "implementation";
              "<leader>gt" = "type_definition";
            };
          };
        };

        lsp-format = {
          enable = true;
          setup = {
            nix = {
            };
          };
        };

        nvim-cmp = {
          enable = true;
          autoEnableSources = true;
          sources = [
            {
              name = "nvim_lsp";
            }
            {
              name = "luasnip";
            }
            {
              name = "path";
            }
            {
              name = "buffer";
            }
          ];
          mapping = {
            "<C-Space>" = "cmp.mapping.complete()";
            "<C-e>" = "cmp.mapping.close()";
            "<Tab>" = {
              modes = ["i" "s"];
              action = "cmp.mapping.select_next_item()";
            };
            "<S-Tab>" = {
              modes = ["i" "s"];
              action = "cmp.mapping.select_prev_item()";
            };
            "<CR>" = "cmp.mapping.confirm({ select = true })";
          };
        };


	 rainbow-delimiters = {
        enable = true;
      };
      nvim-colorizer.enable = true;

      undotree.enable = true;

      which-key = {
        enable = true;
        registrations = {
          "<leader>K" = "Code hover";
          "<leader>gf" = "Code references";
          "<leader>gd" = "Code definitions";
          "<leader>gi" = "Implementations";
          "<leader>gt" = "Type definition";
        };
      };

      trouble.enable = true;

      markdown-preview.enable = true;
      };
    };
  };
}
