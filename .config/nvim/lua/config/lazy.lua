local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    lazyrepo,
    lazypath,
  })

  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("lazy").setup({
  spec = {
    {
      "neovim/nvim-lspconfig",
      config = function()
        -- LSPが有効になったバッファだけに、LSP用のキーマップを設定する。
        vim.api.nvim_create_autocmd("LspAttach", {
          group = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true }),
          callback = function(event)
            -- `buffer = event.buf` を指定して、PHP以外の通常バッファへ影響を広げない。
            local function map(lhs, rhs, desc)
              vim.keymap.set("n", lhs, rhs, { buffer = event.buf, desc = desc })
            end

            -- よく使うLSP操作をNeovim標準のLua APIに割り当てる。
            map("gd", vim.lsp.buf.definition, "LSP: 定義へジャンプ")
            map("gi", vim.lsp.buf.implementation, "LSP: 実装へジャンプ")
            map("gr", vim.lsp.buf.references, "LSP: 参照を表示")
            map("gy", vim.lsp.buf.type_definition, "LSP: 型定義へジャンプ")
            map("K", vim.lsp.buf.hover, "LSP: ホバー情報を表示")
            map("<leader>rn", vim.lsp.buf.rename, "LSP: 名前変更")
            map("<leader>ca", vim.lsp.buf.code_action, "LSP: コードアクション")
            map("<leader>e", vim.diagnostic.open_float, "LSP: 現在行の診断を表示")
            map("[d", vim.diagnostic.goto_prev, "LSP: 前の診断へ移動")
            map("]d", vim.diagnostic.goto_next, "LSP: 次の診断へ移動")
          end,
        })

        vim.lsp.config("phpactor", {
          cmd = { "phpactor", "language-server" },
          filetypes = { "php" },
          root_markers = { ".git", "composer.json", ".phpactor.json", ".phpactor.yml" },
          workspace_required = true,
          init_options = {
            ["language_server_phpstan.enabled"] = false,
            ["language_server_psalm.enabled"] = false,
          },
        })

        vim.lsp.enable("phpactor")
      end,
    },
    {
      "lewis6991/gitsigns.nvim",
      event = { "BufReadPre", "BufNewFile" },
      opts = {
        current_line_blame = true,
        current_line_blame_opts = {
          virt_text = true,
          virt_text_pos = "eol",
          delay = 500,
          ignore_whitespace = false,
        },
        current_line_blame_formatter = "<author>, <author_time:%R> - <summary>",
      },
    },
    {
      "stevearc/oil.nvim",
      ---@module "oil"
      ---@type oil.SetupOpts
      opts = {},
      dependencies = { { "nvim-mini/mini.icons", opts = {} } },
      lazy = false,
      keys = {
        { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
      },
    },
    {
      "iamcco/markdown-preview.nvim",
      cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
      ft = { "markdown" },
      build = function()
        require("lazy").load({ plugins = { "markdown-preview.nvim" } })
        vim.fn["mkdp#util#install_sync"](1)
      end,
    },
  },
  install = { colorscheme = { "habamax" } },
  checker = { enabled = true },
})
