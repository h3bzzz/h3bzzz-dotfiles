-- Rust extras: crates.nvim (Cargo.toml management) + rustaceanvim settings.
-- rustaceanvim itself is installed by the lazyvim lang.rust extra; here we only
-- extend its rust-analyzer settings (migrated from the old lspconfig block that
-- caused a duplicate rust-analyzer client).
return {
  -- crates.nvim: dependency versions, upgrades, features, docs in Cargo.toml
  {
    "saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    tag = "stable",
    opts = {
      -- Built-in LSP source powers completion/hover/actions via blink.cmp
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    },
    config = function(_, opts)
      require("crates").setup(opts)

      vim.api.nvim_create_autocmd("BufRead", {
        group = vim.api.nvim_create_augroup("crates_keymaps", { clear = true }),
        pattern = "Cargo.toml",
        callback = function()
          local crates = require("crates")
          local map = function(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = true, silent = true, desc = desc })
          end
          map("<leader>cu", crates.update_crate, "Update crate")
          map("<leader>cU", crates.upgrade_crate, "Upgrade crate")
          map("<leader>ca", crates.update_all_crates, "Update all crates")
          map("<leader>cv", crates.show_versions_popup, "Show versions")
          map("<leader>cf", crates.show_features_popup, "Show features")
          map("<leader>cd", crates.open_documentation, "Open docs")
        end,
      })
    end,
  },

  -- rustaceanvim: extend rust-analyzer settings (does NOT re-declare the plugin's
  -- version; lazy.nvim merges this fragment with the lang.rust extra's spec).
  {
    "mrcjkb/rustaceanvim",
    init = function()
      vim.g.rustaceanvim = vim.tbl_deep_extend("force", vim.g.rustaceanvim or {}, {
        server = {
          default_settings = {
            ["rust-analyzer"] = {
              cargo = {
                allFeatures = true,
                loadOutDirsFromCheck = true,
                runBuildScripts = true,
              },
              checkOnSave = true,
              check = {
                command = "clippy",
                extraArgs = { "--no-deps" },
              },
              procMacro = {
                enable = true,
                ignored = {
                  ["async-trait"] = { "async_trait" },
                  ["napi-derive"] = { "napi" },
                  ["async-recursion"] = { "async_recursion" },
                },
              },
              inlayHints = {
                bindingModeHints = { enable = true },
                chainingHints = { enable = true },
                closingBraceHints = { enable = true },
                closureReturnTypeHints = { enable = "always" },
                lifetimeElisionHints = { enable = "always" },
                parameterHints = { enable = true },
                reborrowHints = { enable = "always" },
                renderColons = true,
                typeHints = { enable = true },
                maxLength = 25,
              },
            },
          },
        },
      })
    end,
  },
}
