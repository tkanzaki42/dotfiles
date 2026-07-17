# dotfiles

Git と GNU Stow で管理する個人用 dotfiles。

## Setup

### 初回セットアップ

リポジトリを clone する:

```sh
git clone <repository-url> ~/dotfiles
cd ~/dotfiles
```

Stow をインストールする:

```sh
brew install stow
```

設定ファイルの symlink を作成する:

```sh
stow nvim wezterm
```

これで以下のようにリンクされる:

```text
~/.config/nvim    -> ~/dotfiles/nvim/.config/nvim
~/.config/wezterm -> ~/dotfiles/wezterm/.config/wezterm
```

## Structure

トップレベルの各ディレクトリが Stow package になっている。

```text
dotfiles/
├── nvim/.config/nvim/
└── wezterm/.config/wezterm/
```

## Commands

```sh
# symlink を作成
stow nvim wezterm

# symlink を削除
stow -D nvim
stow -D wezterm

# symlink を作り直す
stow -R nvim wezterm
```
