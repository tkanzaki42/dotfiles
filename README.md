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

Nix が入っている環境では、CLIツールを Home Manager で管理する。
使用中のmacOSアカウントに対応する設定名を指定する:

```sh
cd ~/dotfiles
# t_kanzaki の場合
nix run github:nix-community/home-manager -- switch --flake .#t_kanzaki

# blp680 の場合
nix run github:nix-community/home-manager -- switch --flake .#blp680
```

この設定で管理する主なツール:

```text
analog-clock
weztermlayout
wezterm
nvim
tree-sitter
phpactor
php 8.4
composer
node.js 22
sqruff
mariadb-client
```

`analog-clock` はターミナル上でアナログ時計を表示する。初回起動時に
`~/.config/tty-clock/analog.json` を作成し、以降はその設定を使う。
デフォルトでは `tty-clock@0.2.0` を使い、`TTY_CLOCK_NPM_PACKAGE` で上書きできる。

Home Managerを適用せずに一度だけ実行する:

```sh
cd ~/dotfiles
nix run .#analog-clock
nix run .#weztermlayout
```

一時的に環境へ入ってから実行する:

```sh
cd ~/dotfiles
nix develop
analog-clock
weztermlayout
```

`weztermlayout` は WezTerm の中で実行する。現在のペインを中央の作業ペインとして残し、
左に `codex`、右上に `analog-clock`、右下に通常ターミナルを作る。短い alias として
`wezlayout` も使える。WezTerm本体と `codex` はPATH上にある前提で、WezTerm CLIの場所は
`WEZTERM_BIN` で上書きできる。比率や起動コマンドは `WEZTERMLAYOUT_*` 環境変数で上書きできる。

`phpactor` は Neovim のPHP LSPとして使う。Neovimプラグイン自体は引き続き `lazy.nvim` で管理する。
PHPデバッグには `nvim-dap`、`nvim-dap-ui`、Mason管理の `php-debug-adapter` を使う。
PHPファイルで `F9` でブレークポイントを切り替え、`F5` でXdebug待受を開始する。
`F10` / `F11` / `F12` はそれぞれステップオーバー / イン / アウト。
`Space`、`x` 配下からも同じ操作とDAP UIの切り替え、式の評価ができる。
Docker内のパスは既知のPHPリポジトリ名から自動判定し、必要な場合は
`NVIM_PHP_XDEBUG_REMOTE_ROOT` でコンテナ内のプロジェクトルートを上書きできる。
`sqruff` は SQL formatter/linter として使い、Neovim の LSP から `sqruff lsp` を起動する。
NeovimのSQLクライアントには `vim-dadbod` と `vim-dadbod-ui` を使う。`Space`、`d`、`b` の順に
押すとDBUIを開閉でき、`Space`、`d`、`a` で接続先を追加できる。MySQL/MariaDB接続用の
`mysql` CLIはHome Managerの `mariadb-client` で導入する。PostgreSQLなど他のDBを使う場合は、
dadbodが呼び出す対応CLIを別途 `home.packages` に追加する。
`tree-sitter` は `render-markdown.nvim` が使うMarkdown parserのインストールと更新に使う。
Neovim内のターミナルは `toggleterm.nvim` で管理し、ノーマルモードで `Space`、`t`、`t` の順に
押すとフローティングウィンドウで開閉する。`Ctrl+\`（日本語キーボードでは `Ctrl+¥`）も利用できる。
初回起動時は `lazy.nvim` がプラグインを自動で取得する。

手動で入れた `~/.local/bin/phpactor` がある場合は、Home Manager適用後にPATHの優先順を確認する:

```sh
command -v phpactor
phpactor --version
```

## Structure

ホームディレクトリ配下の構成に合わせて配置する。

```text
dotfiles/
├── .gitignore
├── flake.nix
├── home.nix
├── packages/
│   ├── analog-clock.nix
│   └── weztermlayout.nix
└── .config/
    ├── nvim/
    └── wezterm/
```

`.serena/` とリポジトリ直下の `nvim.log` はローカル生成物としてGitの管理対象外にする。

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
