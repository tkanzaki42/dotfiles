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
imagemagick
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
`wezlayout` も使える。右上の時計は起動時にアナログ表示と秒針を有効にする。
WezTerm本体と `codex` はPATH上にある前提で、WezTerm CLIの場所は
`WEZTERM_BIN` で上書きできる。比率や起動コマンドは `WEZTERMLAYOUT_*` 環境変数で上書きできる。

### 個人用・会社用の作業開始

Home Manager を適用したら、WezTerm 内で以下を実行する:

```sh
play  # 個人用レイアウト（左に個人用 Codex）
work  # 会社用レイアウト（左に会社用 Codex）
```

`wezlayout` / `weztermlayout` は個人用がデフォルト。
`wezlayout work` / `wezlayout personal` でも指定できる。
`WEZTERMLAYOUT_CODEX_CMD` / `WEZLAYOUT_CODEX_CMD` が設定されている場合は、
どちらのモードでもその起動コマンドが優先されるため、アカウントを分ける場合は解除する。
各コマンドは現在のペインから新しく分割するため、既存レイアウトの切り替えには使わず、
新しいタブなどで実行する。

Codex だけを起動するコマンドも用意する:

```sh
codex-personal  # CODEX_HOME=~/.codex（既存の設定・認証を使用）
codex-work      # CODEX_HOME=~/.codex-work（会社用）
```

通常の `codex` は引き続き既存の個人用環境として使う。
シェルで `CODEX_HOME` を別の場所に設定している場合は解除するか、`codex-personal` を使う。
既存の `~/.codex` が会社アカウントの場合は、`codex-personal login` で個人用にログインし直す。
会社用は初回に以下を実行し、ブラウザで会社アカウント・会社ワークスペースを選ぶ:

```sh
codex-work login
```

`codex-work` は初回起動時に `~/.codex-work` を作成し、認証情報を
その中の `auth.json` に保存する。設定・履歴も個人用と分かれる。
必要な会社用設定や MCP は `~/.codex-work/config.toml` などに別途設定する。
認証ファイルや履歴は dotfiles にコピーせず、Git 管理に入れない。

Home Manager 適用前にレイアウトを試す場合:

```sh
nix run .#weztermlayout -- work
nix run .#weztermlayout -- personal
```

`phpactor` は Neovim のPHP LSPとして使う。Neovimプラグイン自体は引き続き `lazy.nvim` で管理する。
画像プレビューには `snacks.nvim` の image 機能を使う。`nvim photo.png` や
`:edit photo.jpg` で画像を開ける。SVG・ICOもプレビュー対象に含める。
アニメーションGIFは先頭フレームを静止画として表示する。
画像形式の変換には Home Manager 管理の ImageMagick を使う。
Oil の自動プレビューと fzf-lua のプレビューでも画像表示を利用する。
WezTermでは画像ファイルの表示に対応するが、Markdown本文中へのインライン表示には対応しない。
表示に問題がある場合は `:checkhealth snacks` で確認する。
PHPデバッグには `nvim-dap`、`nvim-dap-ui`、Mason管理の `php-debug-adapter` を使う。
PHPファイルで `F9` でブレークポイントを切り替え、`F5` でXdebug待受を開始する。
`F10` / `F11` / `F12` はそれぞれステップオーバー / イン / アウト。
`Space`、`x` 配下からも同じ操作とDAP UIの切り替え、式の評価ができる。
Docker内のパスは `~/.config/nvim-local/php-xdebug-remote-roots.json` の対応表から
PHPリポジトリ名で判定する。このファイルはdotfilesの外で管理する。
必要な場合だけ `~/.config/nvim-local` を作成し、以下の形式で保存する:

```json
{
  "example-project": "/var/www/html"
}
```

対応表がない場合や該当するリポジトリがない場合は `/var/www/html` を使う。
`NVIM_PHP_XDEBUG_REMOTE_ROOT` が設定されている場合は、対応表より優先して
コンテナ内のプロジェクトルートを上書きする。
会社固有の対応表はdotfilesにコピーせず、Git管理に入れない。
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
`packages/weztermlayout.nix` は `weztermlayout` / `wezlayout` に加え、
`work` / `play` と `codex-work` / `codex-personal` も提供する。

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
