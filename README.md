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
analog-clock
nvim
phpactor
php 8.4
composer
sqruff
```

`analog-clock` はターミナル上でアナログ時計を表示する。初回起動時に
`~/.config/tty-clock/analog.json` を作成し、以降はその設定を使う。
デフォルトでは `tty-clock@0.2.0` を使い、`TTY_CLOCK_NPM_PACKAGE` で上書きできる。

Home Managerを適用せずに一度だけ実行する:

```sh
cd ~/dotfiles
nix run .#analog-clock
```

一時的に環境へ入ってから実行する:

```sh
cd ~/dotfiles
nix develop
analog-clock
```

`phpactor` は Neovim のPHP LSPとして使う。Neovimプラグイン自体は引き続き `lazy.nvim` で管理する。
`sqruff` は SQL formatter/linter として使い、Neovim の LSP から `sqruff lsp` を起動する。

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
├── packages/
│   └── analog-clock.nix
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
