{
  bash,
  symlinkJoin,
  writeShellApplication,
  zsh,
}:

let
  weztermLayout = writeShellApplication {
    name = "weztermlayout";
    runtimeInputs = [
      bash
      zsh
    ];

    text = ''
      die() {
        printf 'weztermlayout: %s\n' "$*" >&2
        exit 1
      }

      validate_percent() {
        local name=$1
        local value=$2

        if [[ ! "$value" =~ ^[0-9]+$ ]] || (( value < 1 || value > 99 )); then
          die "$name must be an integer between 1 and 99"
        fi
      }

      print_command() {
        printf '+'
        printf ' %q' "$@"
        printf '\n'
      }

      wezterm_bin=''${WEZTERM_BIN:-}
      if [[ -z "$wezterm_bin" ]]; then
        wezterm_bin=$(command -v wezterm || true)
      fi
      if [[ -z "$wezterm_bin" && -x /opt/homebrew/bin/wezterm ]]; then
        wezterm_bin=/opt/homebrew/bin/wezterm
      fi

      [[ -n "$wezterm_bin" ]] || die "wezterm command not found"
      [[ -n "''${WEZTERM_PANE:-}" ]] || die "run this inside a WezTerm pane"

      main_pane=$WEZTERM_PANE
      cwd=''${WEZTERMLAYOUT_CWD:-''${WEZLAYOUT_CWD:-$PWD}}

      # Ratios taken from the reference layout:
      # left/middle/right = 45/147/78 cols, right top/bottom = 27/38 rows.
      left_percent=''${WEZTERMLAYOUT_LEFT_PERCENT:-''${WEZLAYOUT_LEFT_PERCENT:-17}}
      right_percent=''${WEZTERMLAYOUT_RIGHT_PERCENT:-''${WEZLAYOUT_RIGHT_PERCENT:-35}}
      right_bottom_percent=''${WEZTERMLAYOUT_RIGHT_BOTTOM_PERCENT:-''${WEZLAYOUT_RIGHT_BOTTOM_PERCENT:-58}}

      codex_cmd=''${WEZTERMLAYOUT_CODEX_CMD:-''${WEZLAYOUT_CODEX_CMD:-codex}}
      clock_cmd=''${WEZTERMLAYOUT_CLOCK_CMD:-''${WEZLAYOUT_CLOCK_CMD:-analog-clock}}

      validate_percent WEZTERMLAYOUT_LEFT_PERCENT "$left_percent"
      validate_percent WEZTERMLAYOUT_RIGHT_PERCENT "$right_percent"
      validate_percent WEZTERMLAYOUT_RIGHT_BOTTOM_PERCENT "$right_bottom_percent"

      if [[ "''${WEZTERMLAYOUT_DRY_RUN:-''${WEZLAYOUT_DRY_RUN:-}}" == 1 ]]; then
        print_command "$wezterm_bin" cli split-pane --pane-id "$main_pane" --left --percent "$left_percent" --cwd "$cwd" -- zsh -lc "exec $codex_cmd"
        print_command "$wezterm_bin" cli split-pane --pane-id "$main_pane" --right --percent "$right_percent" --cwd "$cwd" -- zsh -lc "exec $clock_cmd"
        print_command "$wezterm_bin" cli split-pane --pane-id '<right-pane-id>' --bottom --percent "$right_bottom_percent" --cwd "$cwd"
        print_command "$wezterm_bin" cli activate-pane --pane-id "$main_pane"
        exit 0
      fi

      left_pane=$("$wezterm_bin" cli split-pane --pane-id "$main_pane" --left --percent "$left_percent" --cwd "$cwd" -- zsh -lc "exec $codex_cmd")
      right_pane=$("$wezterm_bin" cli split-pane --pane-id "$main_pane" --right --percent "$right_percent" --cwd "$cwd" -- zsh -lc "exec $clock_cmd")
      bottom_pane=$("$wezterm_bin" cli split-pane --pane-id "$right_pane" --bottom --percent "$right_bottom_percent" --cwd "$cwd")

      "$wezterm_bin" cli activate-pane --pane-id "$main_pane"

      printf 'layout ready: codex=%s main=%s clock=%s terminal=%s\n' "$left_pane" "$main_pane" "$right_pane" "$bottom_pane"
    '';
  };
in
symlinkJoin {
  name = "weztermlayout";
  paths = [ weztermLayout ];
  postBuild = ''
    ln -s weztermlayout "$out/bin/wezlayout"
  '';
}
