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

-- lazy.nvim
require("config.lazy")
