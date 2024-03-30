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
        shiftwidth = 4;
      };

      autoCmd = [
        {
          event = "FileType";
          pattern = "nix";
          command = "setlocal tabstop=2 shiftwidth=2";
        }
      ];

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
          nixGrammars = true;
          indent = true;
        };
        treesitter-context.enable = true;

        lualine.enable = true;

        copilot-lua = {
          panel.enabled = false;
          suggestion.enabled = false;
        };

        nix.enable = true;
        nix-develop.enable = true;

        nvim-autopairs.enable = true;

        rainbow-delimiters = {enable = true;};
        nvim-colorizer.enable = true;

        undotree.enable = true;

        which-key = {enable = true;};

        trouble.enable = true;

        markdown-preview.enable = true;

        dashboard = {enable = true;};

        auto-save = {
          enable = true;
          enableAutoSave = true;
        };

        ## cmp extract into file
        luasnip.enable = true;
        cmp-buffer = {enable = true;};

        cmp-emoji = {enable = true;};

        cmp-nvim-lsp = {enable = true;};

        cmp-path = {enable = true;};

        cmp_luasnip = {enable = true;};

        cmp = {
          enable = true;

          settings = {
            snippet.expand = "luasnip";
            sources = [
              {name = "nvim_lsp";}
              {name = "luasnip";}
              {name = "copilot";}
              {
                name = "buffer";
                option.get_bufnrs.__raw = "vim.api.nvim_list_bufs";
              }
              {name = "nvim_lua";}
              {name = "path";}
            ];

            formatting = {
              fields = ["abbr" "kind" "menu"];
              format =
                # lua
                ''
                  function(_, item)
                    local icons = {
                      Namespace = "󰌗",
                      Text = "󰉿",
                      Method = "󰆧",
                      Function = "󰆧",
                      Constructor = "",
                      Field = "󰜢",
                      Variable = "󰀫",
                      Class = "󰠱",
                      Interface = "",
                      Module = "",
                      Property = "󰜢",
                      Unit = "󰑭",
                      Value = "󰎠",
                      Enum = "",
                      Keyword = "󰌋",
                      Snippet = "",
                      Color = "󰏘",
                      File = "󰈚",
                      Reference = "󰈇",
                      Folder = "󰉋",
                      EnumMember = "",
                      Constant = "󰏿",
                      Struct = "󰙅",
                      Event = "",
                      Operator = "󰆕",
                      TypeParameter = "󰊄",
                      Table = "",
                      Object = "󰅩",
                      Tag = "",
                      Array = "[]",
                      Boolean = "",
                      Number = "",
                      Null = "󰟢",
                      String = "󰉿",
                      Calendar = "",
                      Watch = "󰥔",
                      Package = "",
                      Copilot = "",
                      Codeium = "",
                      TabNine = "",
                    }

                    local icon = icons[item.kind] or ""
                    item.kind = string.format("%s %s", icon, item.kind or "")
                    return item
                  end
                '';
            };

            window = {
              completion = {
                winhighlight = "FloatBorder:CmpBorder,Normal:CmpPmenu,CursorLine:CmpSel,Search:PmenuSel";
                scrollbar = false;
                sidePadding = 0;
                border = ["╭" "─" "╮" "│" "╯" "─" "╰" "│"];
              };

              settings.documentation = {
                border = ["╭" "─" "╮" "│" "╯" "─" "╰" "│"];
                winhighlight = "FloatBorder:CmpBorder,Normal:CmpPmenu,CursorLine:CmpSel,Search:PmenuSel";
              };
            };

            mapping = {
              "<C-n>" = "cmp.mapping.select_next_item()";
              "<C-p>" = "cmp.mapping.select_prev_item()";
              "<C-j>" = "cmp.mapping.select_next_item()";
              "<C-k>" = "cmp.mapping.select_prev_item()";
              "<C-d>" = "cmp.mapping.scroll_docs(-4)";
              "<C-f>" = "cmp.mapping.scroll_docs(4)";
              "<C-Space>" = "cmp.mapping.complete()";
              "<C-e>" = "cmp.mapping.close()";
              "<CR>" = "cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Insert, select = true })";
              "<Tab>" =
                # lua
                ''
                  function(fallback)
                    if cmp.visible() then
                      cmp.select_next_item()
                    elseif require("luasnip").expand_or_jumpable() then
                      vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-expand-or-jump", true, true, true), "")
                    else
                      fallback()
                    end
                  end
                '';
              "<S-Tab>" =
                # lua
                ''
                  function(fallback)
                    if cmp.visible() then
                      cmp.select_prev_item()
                    elseif require("luasnip").jumpable(-1) then
                      vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-jump-prev", true, true, true), "")
                    else
                      fallback()
                    end
                  end
                '';
            };
          };
        };

        ## lsp
        lsp = {
          enable = true;
          servers = {
            fsautocomplete.enable = true;
            nixd.enable = true;
          };
          keymaps.lspBuf = {
            "<leader>gd" = "definition";
            "<leader>gD" = "references";
            "<leader>gt" = "type_definition";
            "<leader>gi" = "implementation";
            "<leader>K" = "hover";
          };
        };
        rust-tools.enable = true;

        ## none-ls
        none-ls = {
          enable = true;
          sources = {
            diagnostics = {statix.enable = true;};
            formatting = {
              nixfmt.enable = true;
              markdownlint.enable = true;
              shellharden.enable = true;
              shfmt.enable = true;
            };
          };
        };
      };
    };
  };
}
