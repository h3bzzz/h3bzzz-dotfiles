return {
  -- Mason (mason-org fork)
  {
    "mason-org/mason.nvim",
    version = "*",
    -- opts is a FUNCTION (not a table) so it runs AFTER lazy has merged in the
    -- ensure_installed lists from LazyVim core and every lang/formatting/linting
    -- extra. LazyVim's mason config (lsp/init.lua) then calls p:install() on
    -- every entry unconditionally -- so any package listed twice (e.g. gofumpt
    -- from lang.go + here, prettier from formatting.prettier + here) gets two
    -- concurrent installs and mason throws "Package is already installing.".
    -- We append our extras, then dedupe the whole list to kill that race for
    -- good, no matter which extras add what.
    -- LSP servers (gopls, zls, pyright, lua_ls, clangd, ts_ls) are intentionally
    -- absent: mason-lspconfig installs those from the lspconfig `servers` table.
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "rust-analyzer", -- owned by rustaceanvim; nothing else installs it
        -- Formatters
        "gofumpt",
        "goimports-reviser",
        "golines",
        "prettier",
        "black",
        -- Linters
        "golangci-lint",
        "eslint_d",
        "flake8",
      })
      local seen, deduped = {}, {}
      for _, pkg in ipairs(opts.ensure_installed) do
        if not seen[pkg] then
          seen[pkg] = true
          deduped[#deduped + 1] = pkg
        end
      end
      opts.ensure_installed = deduped
    end,
  },

  -- Mason LSP bridge
  {
    "mason-org/mason-lspconfig.nvim",
    version = "*",
    dependencies = {
      "mason-org/mason.nvim",
    },
  },

  -- LSP configuration
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- TypeScript
        ts_ls = {
          enabled = true,
          settings = {
            typescript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
              format = {
                indentSize = 2,
                tabSize = 2,
              },
            },
            javascript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayVariableTypeHints = true,
              },
            },
          },
        },

        -- Explicitly disable legacy tsserver
        tsserver = {
          enabled = false,
        },

        -- Zig
        zls = {
          cmd = { vim.fn.stdpath("data") .. "/mason/packages/zls/zls" },
          settings = {
            zls = {
              enable_snippets = true,
              enable_autofix = true,
              enable_build_on_save = false,
              enable_inlay_hints = true,
              inlay_hints_show_variable_type_hints = true,
              inlay_hints_show_struct_literal_field_type = true,
              inlay_hints_show_parameter_name = true,
              inlay_hints_exclude_single_argument = false,
              inlay_hints_hide_redundant_param_names = true,
              inlay_hints_hide_redundant_param_names_last_token = true,
              warn_style = true,
            },
          },
        },

        -- Go
        gopls = {
          settings = {
            gopls = {
              build = {
                allowModfileModifications = false,
                allowVendor = true,
              },
              analyses = {
                unusedparams = true,
                shadow = true,
                fieldalignment = true,
                nilness = true,
                httpresponse = true,
                unmarshal = true,
                unusedwrite = true,
              },
              staticcheck = true,
              gofumpt = true,
              usePlaceholders = true,
              completeUnimported = true,
              completionDocumentation = true,
              hoverKind = "FullDocumentation",
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },
              codelenses = {
                gc_details = true,
                generate = true,
                regenerate_cgo = true,
                run_govulncheck = true,
                test = true,
                tidy = true,
                upgrade_dependency = true,
                vendor = true,
              },
            },
          },
        },

        -- Lua
        lua_ls = {
          settings = {
            Lua = {
              runtime = {
                version = "LuaJIT",
                pathStrict = true,
              },
              diagnostics = {
                globals = { "vim", "love" },
                disable = { "missing-fields" },
              },
              workspace = {
                checkThirdParty = false,
                library = {
                  vim.env.VIMRUNTIME,
                  "${3rd}/love2d/library",
                },
              },
              completion = {
                callSnippet = "Replace",
                keywordSnippet = "Replace",
                displayContext = 10,
              },
              telemetry = {
                enable = false,
              },
              hint = {
                enable = true,
                arrayIndex = "Disable",
                await = true,
                paramName = "Disable",
                paramType = false,
                semicolon = "Disable",
                setType = true,
              },
              format = {
                enable = true,
                defaultConfig = {
                  indent_style = "space",
                  indent_size = "2",
                },
              },
            },
          },
        },

        -- Python
        pyright = {
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "basic",
                autoImportCompletions = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "workspace",
                inlayHints = {
                  callArgumentNames = true,
                  functionReturnTypes = true,
                  variableTypes = true,
                },
              },
            },
          },
        },

        -- C / C++
        clangd = {
          keys = {
            { "<leader>cR", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "Switch Source/Header (C/C++)" },
          },
          root_markers = {
            "Makefile",
            "configure.ac",
            "configure.in",
            "config.h.in",
            "meson.build",
            "meson_options.txt",
            "build.ninja",
            "compile_commands.json",
            "compile_flags.txt",
            ".git",
          },
          capabilities = {
            offsetEncoding = { "utf-16" },
          },
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
            "--cross-file-rename",
          },
          init_options = {
            usePlaceholders = true,
            completeUnimported = true,
            clangdFileStatus = true,
          },
        },

        -- Rust: rust_analyzer is owned by rustaceanvim (lang.rust extra).
        -- Do NOT configure it here or you get two rust-analyzer clients.
        -- Settings live in lua/plugins/rust-crates.lua via vim.g.rustaceanvim.
      },
    },
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "cpp",
        "css",
        "go",
        "gomod",
        "gosum",
        "gowork",
        "html",
        "javascript",
        "json",
        "jsonc",
        "lua",
        "luadoc",
        "markdown",
        "markdown_inline",
        "python",
        "regex",
        "rust",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
        "zig",
      },
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = {
        enable = true,
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner",
          },
        },
      },
    },
  },
}


