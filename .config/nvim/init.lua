-- 背景色を透明に
vim.api.nvim_set_hl(0, "Normal", {
  bg = "NONE",
  ctermbg = "NONE",
  update = true,
})

-- 行番号表示
vim.opt.number = true

-- 相対行表示
vim.opt.relativenumber = true

-- ヤンクをシステムクリップボードに共有
vim.opt.clipboard = "unnamedplus"

-- Option + 矢印で行を上下に移動
vim.keymap.set("n", "<A-Up>", ":m .-2<CR>==", { desc = "Move line up", silent = true })
vim.keymap.set("n", "<A-Down>", ":m .+1<CR>==", { desc = "Move line down", silent = true })
vim.keymap.set("v", "<A-Up>", ":m '<-2<CR>gv=gv", { desc = "Move selection up", silent = true })
vim.keymap.set("v", "<A-Down>", ":m '>+1<CR>gv=gv", { desc = "Move selection down", silent = true })
vim.keymap.set("i", "<A-Up>", "<Esc>:m .-2<CR>==gi", { desc = "Move line up", silent = true })
vim.keymap.set("i", "<A-Down>", "<Esc>:m .+1<CR>==gi", { desc = "Move line down", silent = true })

-- lazy.nvim
require("config.lazy")
