return {
  -- Mason (mason-org fork)
  {
    "mason-org/mason.nvim",
    version = "*",
    opts = {
      ensure_installed = {
        "gopls",
        "zls",
        "pyright",
        "lua-language-server",
        "clangd",
        "typescript-language-server",
        "rust-analyzer",
      },
    },
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
          settings = {
            zls = {
              enable_snippets = true,
              enable_autofix = true,
              enable_build_on_save = true,
              build_on_save_step = "check",
            },
          },
        },

        -- Go
        gopls = {
          settings = {
            gopls = {
              analyses = {
                unusedparams = true,
                shadow = true,
              },
              staticcheck = true,
              gofumpt = true,
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
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
              },
              diagnostics = {
                globals = { "vim", "love" },
              },
              workspace = {
                checkThirdParty = false,
                library = {
                  vim.env.VIMRUNTIME,
                  "/usr/share/lua/5.1",
                  "/usr/share/love",
                },
              },
              completion = {
                callSnippet = "Replace",
              },
              telemetry = {
                enable = false,
              },
            },
          },
        },

        -- Python
        pyright = {},

        -- C / C++
        clangd = {
          keys = {
            { "<leader>cR", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "Switch Source/Header (C/C++)" },
          },
          root_dir = function(fname)
            local util = require("lspconfig.util")
            return util.root_pattern(
              "Makefile",
              "configure.ac",
              "configure.in",
              "config.h.in",
              "meson.build",
              "meson_options.txt",
              "build.ninja"
            )(fname)
              or util.root_pattern(
                "compile_commands.json",
                "compile_flags.txt"
              )(fname)
              or util.find_git_ancestor(fname)
          end,
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
          },
          init_options = {
            usePlaceholders = true,
            completeUnimported = true,
            clangdFileStatus = true,
          },
        },

        -- Rust
        rust_analyzer = {
          settings = {
            ["rust-analyzer"] = {
              cargo = {
                allFeatures = true,
              },
              checkOnSave = {
                command = "clippy",
              },
            },
          },
        },
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
        "html",
        "javascript",
        "json",
        "lua",
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
    },
  },
}

