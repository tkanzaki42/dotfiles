# dotfiles

## Setup

### 初回セットアップ

リポジトリを clone する:

```sh
git clone <repository-url> ~/dotfiles
cd ~/dotfiles
```

設定ファイルの symlink を作成する:

```sh
mkdir -p ~/.config
ln -s ~/dotfiles/.config/nvim ~/.config/nvim
ln -s ~/dotfiles/.config/wezterm ~/.config/wezterm
```

これで以下のようにリンクされる:

```text
~/.config/nvim    -> ~/dotfiles/.config/nvim
~/.config/wezterm -> ~/dotfiles/.config/wezterm
```

## Structure

ホームディレクトリ配下の構成に合わせて配置する。

```text
dotfiles/
└── .config/
    ├── nvim/
    └── wezterm/
```

## Commands

```sh
# symlink を作成
mkdir -p ~/.config
ln -s ~/dotfiles/.config/nvim ~/.config/nvim
ln -s ~/dotfiles/.config/wezterm ~/.config/wezterm

# symlink を削除
unlink ~/.config/nvim
unlink ~/.config/wezterm
```
