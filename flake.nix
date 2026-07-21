{
  description = "t_kanzaki dotfiles";

  inputs = {
    # Home Managerで使うパッケージ集合。unstableを使い、phpactorなどを新しめに保つ。
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # ユーザー環境を宣言的に管理するHome Manager。
    home-manager = {
      url = "github:nix-community/home-manager";
      # Home Manager内部でも、このflakeと同じnixpkgsを使う。
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { home-manager, nixpkgs, ... }:
    let
      # 環境変数から読まずに明示することで、flake評価を純粋で再現しやすくする。
      username = "t_kanzaki";
      homeDirectory = "/Users/${username}";

      # systemごとのHome Manager設定を作る共通関数。
      mkHome = system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { inherit system; };
          modules = [
            ./home.nix
            {
              # Home Managerが管理するユーザー名とホームディレクトリ。
              home = {
                inherit username homeDirectory;
              };
            }
          ];
        };
    in
    {
      homeConfigurations = {
        # 現在のmacOS Apple Silicon向けの短い名前。
        "${username}" = mkHome "aarch64-darwin";
        # 明示的にCPU/OSを指定した名前。別マシンで使い分けるために残しておく。
        "${username}-aarch64-darwin" = mkHome "aarch64-darwin";
        "${username}-x86_64-darwin" = mkHome "x86_64-darwin";
      };
    };
}
