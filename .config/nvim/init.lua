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

-- Control + Option + 矢印で境界線を矢印の方向へ移動
local function move_vertical_separator(direction)
  local current_window = vim.fn.winnr()
  local has_window_on_right = vim.fn.winnr("l") ~= current_window
  local has_window_on_left = vim.fn.winnr("h") ~= current_window

  if has_window_on_right then
    vim.cmd("vertical resize " .. (direction == "left" and "-2" or "+2"))
  elseif has_window_on_left then
    vim.cmd("vertical resize " .. (direction == "left" and "+2" or "-2"))
  end
end

local function move_horizontal_separator(direction)
  local current_window = vim.fn.winnr()
  local has_window_below = vim.fn.winnr("j") ~= current_window
  local has_window_above = vim.fn.winnr("k") ~= current_window

  if has_window_below then
    vim.cmd("resize " .. (direction == "up" and "-2" or "+2"))
  elseif has_window_above then
    vim.cmd("resize " .. (direction == "up" and "+2" or "-2"))
  end
end

vim.keymap.set("n", "<C-A-Left>", function()
  move_vertical_separator("left")
end, { desc = "Move window separator left", silent = true })
vim.keymap.set("n", "<C-A-Right>", function()
  move_vertical_separator("right")
end, { desc = "Move window separator right", silent = true })
vim.keymap.set("n", "<C-A-Up>", function()
  move_horizontal_separator("up")
end, { desc = "Move window separator up", silent = true })
vim.keymap.set("n", "<C-A-Down>", function()
  move_horizontal_separator("down")
end, { desc = "Move window separator down", silent = true })

-- lazy.nvim
require("config.lazy")

vim.keymap.set("n", "<leader>yp", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("Copied: " .. path)
end, { desc = "Yank absolute file path" })
