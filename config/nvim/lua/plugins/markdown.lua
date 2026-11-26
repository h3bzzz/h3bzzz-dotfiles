-- Markdown and plain-text reading experience.
--
-- Why this file exists: LazyVim's `lang.markdown` extra wires markdownlint-cli2
-- into BOTH nvim-lint and none-ls, so every style nit is reported twice, and the
-- `lazyvim_wrap_spell` autocmd turns on spell checking for prose. Opening a
-- README you only meant to read becomes a wall of warnings. The specs below turn
-- markdown buffers into a calm reader by default and keep every tool one
-- keystroke away under <leader>m. Buffer options (wrap, spell, autoformat) live
-- in lua/config/autocmds.lua.

return {
  -- 1. No markdownlint diagnostics on open. Lint on demand with <leader>ml.
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.markdown = nil
      opts.linters_by_ft["markdown.mdx"] = nil
    end,
  },
  {
    "nvimtools/none-ls.nvim",
    optional = true,
    opts = function(_, opts)
      opts.sources = vim.tbl_filter(function(source)
        return source.name ~= "markdownlint-cli2"
      end, opts.sources or {})
    end,
  },

  -- 2. Illuminate highlights every repeat of the word under the cursor, which is
  --    useful in code and distracting in prose.
  {
    "RRethy/vim-illuminate",
    optional = true,
    opts = {
      filetypes_denylist = { "dirbuf", "dirvish", "fugitive", "markdown", "markdown.mdx", "text" },
    },
  },

  -- 3. render-markdown.nvim: the in-buffer reader look.
  --    Replaces the smaller spec that used to live in modern-qol.lua. LazyVim's
  --    extra still owns the <leader>um global toggle.
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "markdown.mdx" },
    opts = {
      file_types = { "markdown", "markdown.mdx", "codecompanion" },
      -- Checkbox and callout completions through blink.cmp via the in-process LSP.
      completions = { lsp = { enabled = true } },
      -- Needs utftex or latex2text on PATH; neither is installed.
      latex = { enabled = false },
      sign = { enabled = false },
      heading = {
        sign = false,
        position = "inline",
        icons = { "◉ ", "○ ", "✸ ", "✿ ", "▸ ", "▹ " },
        -- H1/H2 span the window, deeper headings hug their text.
        width = { "full", "full", "block" },
        left_pad = 1,
        right_pad = 2,
        -- Thin top/bottom bars on H1/H2 when the surrounding lines are empty.
        border = { true, true, false },
        border_virtual = false,
      },
      code = {
        sign = false,
        width = "block",
        left_pad = 1,
        right_pad = 2,
        min_width = 45,
        language_pad = 1,
        border = "thin",
      },
      checkbox = {
        enabled = true,
        custom = {
          todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
          important = { raw = "[!]", rendered = "󰅾 ", highlight = "RenderMarkdownWarn" },
        },
      },
      quote = {
        -- Repeats the quote bar on soft-wrapped lines. Depends on showbreak,
        -- breakindent and breakindentopt set in autocmds.lua.
        repeat_linebreak = true,
      },
      pipe_table = {
        preset = "round",
        cell = "padded",
      },
    },
  },

  -- 4. markdown.nvim: editing verbs for when reading turns into writing.
  --    Inline styles over motions (gs{motion}{style}: gsiwb bolds a word),
  --    links, task toggles, list numbering, table of contents, heading jumps.
  {
    "tadmccorkle/markdown.nvim",
    ft = { "markdown", "markdown.mdx" },
    opts = {
      mappings = {
        inline_surround_toggle = "gs",
        inline_surround_toggle_line = "gss",
        -- Not ds/cs: those belong to nvim-surround in every buffer.
        inline_surround_delete = "gsd",
        inline_surround_change = "gsc",
        link_add = "gl",
        link_follow = "gx",
        go_curr_heading = "]c",
        go_parent_heading = "]p",
        -- ]] and [[ are mapped in on_attach below, after illuminate's own
        -- FileType autocmd has had its turn.
        go_next_heading = false,
        go_prev_heading = false,
      },
      on_attach = function(bufnr)
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
        end

        -- vim-illuminate re-maps ]] and [[ for every buffer from a FileType
        -- autocmd. Scheduling runs after all FileType handlers, so these win.
        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(bufnr) then
            return
          end
          map("n", "]]", "<Plug>(markdown_go_next_heading)", "Next heading")
          map("n", "[[", "<Plug>(markdown_go_prev_heading)", "Previous heading")
        end)

        -- Lists
        map({ "n", "i" }, "<M-CR>", "<Cmd>MDListItemBelow<CR>", "New list item below")
        map({ "n", "i" }, "<M-S-CR>", "<Cmd>MDListItemAbove<CR>", "New list item above")

        -- <leader>m: Markdown
        map("n", "<leader>mt", "<Cmd>MDTaskToggle<CR>", "Toggle task")
        map("x", "<leader>mt", ":MDTaskToggle<CR>", "Toggle tasks")
        map("n", "<leader>mn", "<Cmd>MDResetListNumbering<CR>", "Renumber ordered lists")
        map("n", "<leader>mo", "<Cmd>MDInsertToc<CR>", "Insert table of contents")
        map("n", "<leader>mO", "<Cmd>MDToc<CR>", "Outline (location list)")
        map("n", "<leader>mm", function()
          require("render-markdown").buf_toggle()
        end, "Toggle rendering (this buffer)")
        map("n", "<leader>mp", "<Cmd>MarkdownPreviewToggle<CR>", "Preview in browser")
        map("n", "<leader>ml", function()
          local lint = require("lint")
          local ns = lint.get_namespace("markdownlint-cli2")
          if #vim.diagnostic.get(bufnr, { namespace = ns }) > 0 then
            vim.diagnostic.reset(ns, bufnr)
          else
            lint.try_lint("markdownlint-cli2")
          end
        end, "Toggle markdownlint diagnostics")
      end,
    },
  },
}
