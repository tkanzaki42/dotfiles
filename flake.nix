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
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;

      mkPkgs = system: import nixpkgs { inherit system; };

      mkAnalogClock = pkgs: pkgs.callPackage ./packages/analog-clock.nix { };
      mkWeztermLayout = pkgs: pkgs.callPackage ./packages/weztermlayout.nix { };

      # systemごとのHome Manager設定を作る共通関数。
      mkHome = { username, system }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs system;
          modules = [
            ./home.nix
            {
              # Home Managerが管理するユーザー名とホームディレクトリ。
              home = {
                inherit username;
                homeDirectory = "/Users/${username}";
              };
            }
          ];
        };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
          analogClock = mkAnalogClock pkgs;
          weztermLayout = mkWeztermLayout pkgs;
        in
        {
          analog-clock = analogClock;
          weztermlayout = weztermLayout;
          default = analogClock;
        }
      );

      apps = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
          analogClock = mkAnalogClock pkgs;
          weztermLayout = mkWeztermLayout pkgs;
        in
        {
          analog-clock = {
            type = "app";
            program = "${analogClock}/bin/analog-clock";
          };
          weztermlayout = {
            type = "app";
            program = "${weztermLayout}/bin/weztermlayout";
          };
          default = {
            type = "app";
            program = "${analogClock}/bin/analog-clock";
          };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
        in
        {
          default = pkgs.mkShell {
            packages = [
              (mkAnalogClock pkgs)
              (mkWeztermLayout pkgs)
              pkgs.nodejs_22
            ];
          };
        }
      );

      homeConfigurations = {
        # macOS Apple Silicon向けの短い名前。
        t_kanzaki = mkHome {
          username = "t_kanzaki";
          system = "aarch64-darwin";
        };
        blp680 = mkHome {
          username = "blp680";
          system = "aarch64-darwin";
        };

        # 明示的にCPU/OSを指定した名前。別マシンで使い分けるために残しておく。
        t_kanzaki-aarch64-darwin = mkHome {
          username = "t_kanzaki";
          system = "aarch64-darwin";
        };
        t_kanzaki-x86_64-darwin = mkHome {
          username = "t_kanzaki";
          system = "x86_64-darwin";
        };
        blp680-aarch64-darwin = mkHome {
          username = "blp680";
          system = "aarch64-darwin";
        };
        blp680-x86_64-darwin = mkHome {
          username = "blp680";
          system = "x86_64-darwin";
        };
      };
    };
}
