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

### Nix / Home Manager

Nix が入っている環境では、CLIツールを Home Manager で管理する:

```sh
cd ~/dotfiles
nix run github:nix-community/home-manager -- switch --flake .#t_kanzaki
```

この設定で管理する主なツール:

```text
nvim
phpactor
php 8.4
composer
```

`phpactor` は Neovim のPHP LSPとして使う。Neovimプラグイン自体は引き続き `lazy.nvim` で管理する。

手動で入れた `~/.local/bin/phpactor` がある場合は、Home Manager適用後にPATHの優先順を確認する:

```sh
command -v phpactor
phpactor --version
```

## Structure

ホームディレクトリ配下の構成に合わせて配置する。

```text
dotfiles/
├── flake.nix
├── home.nix
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
