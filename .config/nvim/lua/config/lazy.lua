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
      "ricardoramirezr/blade-nav.nvim",
      ft = { "blade", "php" },
      opts = {
        integrations = {
          cmp = false,
          coq = false,
        },
        annotations = {
          create_keymaps = false,
        },
      },
    },
    {
      "kristijanhusak/vim-dadbod-ui",
      dependencies = {
        { "tpope/vim-dadbod", lazy = true },
        {
          "kristijanhusak/vim-dadbod-completion",
          ft = { "sql", "mysql", "plsql" },
          lazy = true,
        },
      },
      cmd = {
        "DBUI",
        "DBUIToggle",
        "DBUIAddConnection",
        "DBUIFindBuffer",
      },
      keys = {
        { "<leader>db", "<cmd>DBUIToggle<cr>", desc = "Database: UI切替" },
        { "<leader>da", "<cmd>DBUIAddConnection<cr>", desc = "Database: 接続を追加" },
        { "<leader>df", "<cmd>DBUIFindBuffer<cr>", desc = "Database: 現在のバッファを表示" },
      },
    },
    {
      "mfussenegger/nvim-dap",
      dependencies = {
        { "mason-org/mason.nvim", opts = {} },
        {
          "jay-babu/mason-nvim-dap.nvim",
          opts = {
            ensure_installed = { "php" },
            handlers = {},
          },
        },
        {
          "rcarriga/nvim-dap-ui",
          dependencies = { "nvim-neotest/nvim-nio" },
        },
      },
      config = function()
        local dap = require("dap")
        local dapui = require("dapui")

        local function php_project_root()
          local current_file = vim.api.nvim_buf_get_name(0)
          local root = vim.fs.root(current_file ~= "" and current_file or 0, { ".git", "composer.json" })
          return root or (vim.uv or vim.loop).cwd()
        end

        local function php_path_mappings()
          local project_root = php_project_root()
          local project_name = vim.fs.basename(project_root)
          local remote_roots = {
            ["bp-store-api"] = "/var/www/html",
            ["front_manage"] = "/var/www/html/manage",
            ["kddi-bp-front_manage"] = "/var/www/html/manage",
            ["kddi-bp-front_uiux_sp"] = "/var/www/html/uiux",
            ["kddi-bp-itemmaster_management-tool"] = "/var/www/management-tool",
          }
          local remote_root = vim.env.NVIM_PHP_XDEBUG_REMOTE_ROOT or remote_roots[project_name] or "/var/www/html"

          return { [remote_root] = project_root }
        end

        dap.configurations.php = {
          {
            type = "php",
            request = "launch",
            name = "PHP: Listen for Xdebug (Docker)",
            hostname = "0.0.0.0",
            port = 9003,
            pathMappings = php_path_mappings,
          },
        }

        dapui.setup()

        dap.listeners.before.attach.php_dapui = function()
          dapui.open()
        end
        dap.listeners.before.launch.php_dapui = function()
          dapui.open()
        end
        dap.listeners.before.event_terminated.php_dapui = function()
          dapui.close()
        end
        dap.listeners.before.event_exited.php_dapui = function()
          dapui.close()
        end

        vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
        vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
        vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticInfo", linehl = "Visual" })
      end,
      keys = {
        { "<F5>", function() require("dap").continue() end, desc = "Debug: 開始/続行" },
        { "<F9>", function() require("dap").toggle_breakpoint() end, desc = "Debug: ブレークポイント切替" },
        { "<F10>", function() require("dap").step_over() end, desc = "Debug: ステップオーバー" },
        { "<F11>", function() require("dap").step_into() end, desc = "Debug: ステップイン" },
        { "<F12>", function() require("dap").step_out() end, desc = "Debug: ステップアウト" },
        { "<leader>xb", function() require("dap").toggle_breakpoint() end, desc = "Debug: ブレークポイント切替" },
        { "<leader>xc", function() require("dap").continue() end, desc = "Debug: 開始/続行" },
        { "<leader>xn", function() require("dap").step_over() end, desc = "Debug: ステップオーバー" },
        { "<leader>xi", function() require("dap").step_into() end, desc = "Debug: ステップイン" },
        { "<leader>xo", function() require("dap").step_out() end, desc = "Debug: ステップアウト" },
        { "<leader>xt", function() require("dap").terminate() end, desc = "Debug: 終了" },
        { "<leader>xu", function() require("dapui").toggle() end, desc = "Debug: UI切替" },
        { "<leader>xe", function() require("dapui").eval() end, mode = { "n", "v" }, desc = "Debug: 式を評価" },
      },
    },
    {
      "saghen/blink.cmp",
      version = "1.*",
      ft = { "sql", "mysql", "plsql" },
      opts = {
        keymap = { preset = "default" },
        completion = {
          documentation = { auto_show = true },
        },
        sources = {
          default = { "dadbod", "buffer" },
          providers = {
            dadbod = {
              name = "Dadbod",
              module = "vim_dadbod_completion.blink",
            },
          },
        },
      },
    },
    {
      "lewis6991/gitsigns.nvim",
      event = { "BufReadPre", "BufNewFile" },
      opts = {
        on_attach = function(bufnr)
          local gitsigns = require("gitsigns")

          local function map(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
          end

          map("]c", function()
            if vim.wo.diff then
              vim.cmd.normal({ "]c", bang = true })
            else
              gitsigns.nav_hunk("next")
            end
          end, "Git: 次の変更へ")

          map("[c", function()
            if vim.wo.diff then
              vim.cmd.normal({ "[c", bang = true })
            else
              gitsigns.nav_hunk("prev")
            end
          end, "Git: 前の変更へ")
        end,
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
          { "<leader>d", group = "Database" },
          { "<leader>g", group = "Git" },
          { "<leader>m", group = "Markdown" },
          { "<leader>p", group = "FzfLua" },
          { "<leader>t", group = "Terminal" },
          { "<leader>x", group = "Debug" },
        },
      },
    },
    {
      "stevearc/oil.nvim",
      ---@module "oil"
      ---@type oil.SetupOpts
      opts = {},
      config = function(_, opts)
        local oil = require("oil")
        oil.setup(opts)

	-- プレビュー表示
        local group = vim.api.nvim_create_augroup("OilAutoPreview", { clear = true })
        vim.api.nvim_create_autocmd("User", {
          group = group,
          pattern = "OilEnter",
          callback = function(event)
            local bufnr = event.data and event.data.buf
            if not bufnr then
              return
            end

            vim.schedule(function()
              if not vim.api.nvim_buf_is_valid(bufnr) then
                return
              end

              local oil_win
              for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
                if vim.api.nvim_win_is_valid(winid) and not vim.w[winid].oil_preview then
                  oil_win = winid
                  break
                end
              end

              if not oil_win then
                return
              end

              local tabpage = vim.api.nvim_win_get_tabpage(oil_win)
              for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
                if vim.w[winid].oil_preview then
                  return
                end
              end

              vim.api.nvim_win_call(oil_win, function()
                oil.open_preview({
                  vertical = true,
                  split = "belowright",
                })
              end)
            end)
          end,
        })
      end,
      dependencies = { { "nvim-mini/mini.icons", opts = {} } },
      lazy = false,
      keys = {
        { "-", "<cmd>Oil<cr>", desc = "Open parent directory with preview" },
      },
    },
    {
      -- nvim内ターミナルの設定
      "akinsho/toggleterm.nvim",
      version = "*",
      lazy = false,
      keys = {
        { "<leader>tt", "<cmd>ToggleTerm<cr>", desc = "Terminal: 開閉" },
      },
      opts = {
        open_mapping = { [[<C-\>]], [[<C-¥>]] },
        direction = "float",
        float_opts = {
          border = "curved",
	  -- 横
          width = function()
            return math.floor(vim.o.columns * 0.8)
          end,
	  -- 縦
          height = function()
            return math.floor(vim.o.lines * 0.9)
          end,
        },
        start_in_insert = true,
        insert_mappings = true,
        terminal_mappings = true,
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
      "nvim-treesitter/nvim-treesitter",
      lazy = false,
      build = ":TSUpdate",
      config = function()
        local missing_parsers = {}

        for _, parser in ipairs({ "markdown", "markdown_inline", "php", "blade", "vue", "html", "sql" }) do
          if not vim.treesitter.language.add(parser) then
            table.insert(missing_parsers, parser)
          end
        end

        if #missing_parsers > 0 then
          require("nvim-treesitter").install(missing_parsers):wait(300000)
        end

        vim.api.nvim_create_autocmd("FileType", {
          group = vim.api.nvim_create_augroup("UserBladeTreesitterHighlight", { clear = true }),
          pattern = { "blade" },
          callback = function(event)
            vim.treesitter.start(event.buf)
          end,
        })

        vim.api.nvim_create_autocmd("FileType", {
          group = vim.api.nvim_create_augroup("UserSqlTreesitterHighlight", { clear = true }),
          pattern = { "sql", "mysql", "plsql" },
          callback = function(event)
            vim.treesitter.start(event.buf, "sql")
          end,
        })

        local function apply_sql_highlights()
          local highlights = {
            ["@keyword.sql"] = { fg = "#fce094", bold = true },
            ["@keyword.conditional.sql"] = { fg = "#fce094", bold = true },
            ["@keyword.modifier.sql"] = { fg = "#fce094", bold = true },
            ["@type.sql"] = { fg = "#8cf8f7" },
            ["@function.call.sql"] = { fg = "#8cf8f7" },
            ["@variable.member.sql"] = { fg = "#a6dbff" },
            ["@string.sql"] = { fg = "#b3f6c0" },
            ["@number.sql"] = { fg = "#ffc0b9" },
            ["@number.float.sql"] = { fg = "#ffc0b9" },
            ["@comment.sql"] = { fg = "#9b9ea4", italic = true },
            ["@operator.sql"] = { fg = "#fce094" },
          }

          for group, options in pairs(highlights) do
            vim.api.nvim_set_hl(0, group, options)
          end
        end

        apply_sql_highlights()

        vim.api.nvim_create_autocmd("ColorScheme", {
          group = vim.api.nvim_create_augroup("UserSqlTreesitterColors", { clear = true }),
          callback = apply_sql_highlights,
        })
      end,
    },
    {
      "MeanderingProgrammer/render-markdown.nvim",
      ft = { "markdown" },
      dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "nvim-mini/mini.icons",
      },
      keys = {
        {
          "<leader>mp",
          "<cmd>RenderMarkdown toggle<cr>",
          desc = "Markdown: プレビュー切替",
          ft = "markdown",
        },
      },
      opts = {},
    },
  },
  install = { colorscheme = { "habamax" } },
  checker = { enabled = true },
  -- 現在のプラグインはLuaRocksを必要としないため、hererocksの導入と警告を無効化する。
  rocks = { enabled = false },
})
