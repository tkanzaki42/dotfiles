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

local fzf_lua_project_rules = require("config.fzf_lua_project_rules")

local function git_commit()
  vim.cmd("tabnew")
  vim.cmd("terminal git commit")
  vim.cmd("startinsert")
end

vim.keymap.set("n", "<leader>gc", git_commit, { desc = "Git: commit" })

local function normalize_path(path)
  if not path or path == "" then
    return ""
  end

  path = path:gsub("^oil://", "")

  local expanded = vim.fn.fnamemodify(path, ":p"):gsub("/$", "")
  return (vim.uv or vim.loop).fs_realpath(expanded) or expanded
end

local function is_subpath(path, root)
  path = normalize_path(path)
  root = normalize_path(root)

  return path == root or path:sub(1, #root + 1) == root .. "/"
end

local function current_fzf_lua_project_rule()
  local cwd = normalize_path((vim.uv or vim.loop).cwd())
  local current_file = normalize_path(vim.api.nvim_buf_get_name(0))

  for _, rule in ipairs(fzf_lua_project_rules) do
    for _, root in ipairs(rule.roots) do
      if is_subpath(cwd, root) then
        return rule, nil
      end

      if is_subpath(current_file, root) then
        return rule, normalize_path(root)
      end
    end
  end

  return nil, nil
end

local function fzf_lua_files_opts()
  local rule, cwd = current_fzf_lua_project_rule()
  local opts = {}

  if cwd then
    opts.cwd = cwd
  end

  if not rule then
    return opts
  end

  local fd_opts = "--color=never --type f --type l --exclude .git --exclude .jj"
  local rg_opts = [[--color=never --files -g "!.git" -g "!.jj"]]

  for _, dir in ipairs(rule.exclude) do
    fd_opts = fd_opts .. " --exclude " .. vim.fn.shellescape(dir)
    rg_opts = rg_opts .. " -g " .. vim.fn.shellescape("!" .. dir .. "/**")
  end

  opts.fd_opts = fd_opts
  opts.rg_opts = rg_opts

  return opts
end

local function fzf_lua_live_grep_opts()
  local rule, cwd = current_fzf_lua_project_rule()
  local opts = {}

  if cwd then
    opts.cwd = cwd
  end

  if not rule then
    return opts
  end

  local rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096"

  for _, dir in ipairs(rule.exclude) do
    rg_opts = rg_opts .. " -g " .. vim.fn.shellescape("!" .. dir .. "/**")
  end

  opts.rg_opts = rg_opts .. " -e"

  return opts
end

local function fzf_lua_git_commits_opts()
  return {
    actions = {
      ["enter"] = {
        fn = function(selected, opts)
          if not selected[1] then
            return
          end

          local commit = selected[1]:match("[^ ]+")
          if not commit then
            return
          end

          local diff_opts = vim.deepcopy(opts.__call_opts or {})
          diff_opts.ref = commit
          diff_opts.ref1 = commit .. "~"
          require("fzf-lua").git_diff(diff_opts)
        end,
        header = "git diff",
      },
    },
  }
end

require("lazy").setup({
  spec = {
    {
      "neovim/nvim-lspconfig",
      config = function()
        -- LSPが有効になったバッファだけに、LSP用のキーマップを設定する。
        vim.api.nvim_create_autocmd("LspAttach", {
          group = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true }),
          callback = function(event)
            -- `buffer = event.buf` を指定して、LSPが付いていない通常バッファへ影響を広げない。
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
            map("<leader>f", function()
              vim.lsp.buf.format({ bufnr = event.buf })
            end, "LSP: フォーマット")
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

        vim.lsp.config("sqruff", {
          cmd = { "sqruff", "--dialect", "mysql", "lsp" },
          filetypes = { "sql", "mysql" },
          root_markers = { ".sqruff", ".git" },
          workspace_required = false,
        })

        vim.lsp.enable("phpactor")
        vim.lsp.enable("sqruff")
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
      "folke/which-key.nvim",
      event = "VeryLazy",
      keys = {
        {
          "<leader>?",
          function()
            require("which-key").show({ global = false })
          end,
          desc = "WhichKey: バッファローカルキー表示",
        },
      },
      opts = {
        preset = "modern",
        spec = {
          { "<leader>g", group = "Git" },
          { "<leader>p", group = "FzfLua" },
        },
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
      "ibhagwan/fzf-lua",
      cmd = "FzfLua",
      keys = {
        {
          "<leader>pf",
          function()
            require("fzf-lua").files(fzf_lua_files_opts())
          end,
          desc = "FzfLua: ファイル検索",
        },
        {
          "<leader>pg",
          function()
            require("fzf-lua").live_grep(fzf_lua_live_grep_opts())
          end,
          desc = "FzfLua: grep検索",
        },
        {
          "<leader>pb",
          function()
            require("fzf-lua").buffers()
          end,
          desc = "FzfLua: バッファ検索",
        },
        {
          "<leader>pr",
          function()
            require("fzf-lua").oldfiles()
          end,
          desc = "FzfLua: 最近開いたファイル",
        },
        {
          "<leader>gs",
          function()
            require("fzf-lua").git_status()
          end,
          desc = "Git: status",
        },
        {
          "<leader>gh",
          function()
            require("fzf-lua").git_hunks()
          end,
          desc = "Git: hunks",
        },
        {
          "<leader>gl",
          function()
            require("fzf-lua").git_commits(fzf_lua_git_commits_opts())
          end,
          desc = "Git: commit log",
        },
        {
          "<leader>ph",
          function()
            require("fzf-lua").help_tags()
          end,
          desc = "FzfLua: ヘルプ検索",
        },
      },
      opts = {},
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
