-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- コンフィグ自動反映
config.automatically_reload_config = true

-- フォントサイズ
config.font_size = 12.0

-- 透明度
config.window_background_opacity = 0.7

-- ぼかし
config.macos_window_background_blur = 4

-- タイトルバーの削除
config.window_decorations = "RESIZE"

-- タブが１つしかないときに非表示
config.hide_tab_bar_if_only_one_tab = true

-- タブバーをコンパクトに
config.use_fancy_tab_bar = false

-- カラースキーマを取得
-- config.color_scheme = 'AdventureTime'    -- Looks cool
-- config.color_scheme = 'Catppuccin Mocha' -- Muted
config.color_scheme = 'Eldritch'         -- Hacker vibe
-- config.color_scheme = 'Iceberg (Dark)'   -- Recommended for coding 

-- マルチディスプレイで別モニターをフォーカス時にノッチ回避機能の裏まで表示
config.macos_fullscreen_extend_behind_notch = true

-- キーバインディング
config.keys = {
    -- バックスラッシュ入力
    {
        key = "raw:93",
        mods = "ALT",
        action = wezterm.action.SendString("\\"),
    },
    -- 単語単位で移動
    {
        key = "LeftArrow",
        mods = "OPT",
        action = wezterm.action.SendKey { key = "b", mods = "ALT" },
    },
    {
        key = "RightArrow",
        mods = "OPT",
        action = wezterm.action.SendKey { key = "f", mods = "ALT" },
    },
    -- ペインリサイズ
    {
        key = "LeftArrow",
        mods = "CTRL|SHIFT|ALT",
        action = wezterm.action.AdjustPaneSize { "Left", 10 },
    },
    {
        key = "RightArrow",
        mods = "CTRL|SHIFT|ALT",
        action = wezterm.action.AdjustPaneSize { "Right", 10 },
    },
    {
        key = "UpArrow",
        mods = "CTRL|SHIFT|ALT",
        action = wezterm.action.AdjustPaneSize { "Up", 5 },
    },
    {
        key = "DownArrow",
        mods = "CTRL|SHIFT|ALT",
        action = wezterm.action.AdjustPaneSize { "Down", 5 },
    },
}

return config
