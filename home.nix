{ pkgs, ... }:

let
  analogClock = pkgs.callPackage ./packages/analog-clock.nix { };
in
{
  # Home Managerの互換性基準。初回導入時のリリースに合わせて固定する。
  home.stateVersion = "26.05";

  # Nixで再現したいユーザー環境のCLIツール。
  # gitやcodexのようなbootstrap/自己管理ツールはここでは管理しない。
  home.packages = [
    # ターミナル上でアナログ時計を表示するラッパー。
    analogClock
    # エディタ本体。設定とプラグイン管理はdotfiles/lazy.nvim側に残す。
    pkgs.neovim
    # PHP実行環境。
    pkgs.php84
    # PHPプロジェクトの依存管理。
    pkgs.php84Packages.composer
    # Neovimから使うPHP LSP本体。
    pkgs.phpactor
  ];

  # `home-manager` コマンド自体もHome Manager管理下に置く。
  programs.home-manager.enable = true;
}
