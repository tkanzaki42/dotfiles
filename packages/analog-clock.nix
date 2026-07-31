{
  coreutils,
  nodejs_22,
  writeShellApplication,
  writeText,
}:

let
  defaultConfig = writeText "tty-clock-analog-config.json" ''
    {
      "mode": "analog",
      "theme": "tokyo-night",
      "customTheme": null,
      "granularity": "seconds",
      "showHelp": true,
      "cellAspect": 0,
      "format": {
        "hour24": true,
        "showSeconds": true,
        "showDate": true,
        "dateFormat": "Mon 2006-01-02",
        "blinkColon": false,
        "font": "block",
        "showNumbers": true
      }
    }
  '';
in
writeShellApplication {
  name = "analog-clock";
  runtimeInputs = [
    coreutils
    nodejs_22
  ];

  text = ''
    config_file="''${TTY_CLOCK_CONFIG:-''${XDG_CONFIG_HOME:-$HOME/.config}/tty-clock/analog.json}"
    config_dir="''${config_file%/*}"

    if [ "$config_dir" = "$config_file" ]; then
      config_dir="."
    fi

    if [ ! -e "$config_file" ]; then
      mkdir -p "$config_dir"
      cp ${defaultConfig} "$config_file"
      chmod u+w "$config_file"
    fi

    exec npm exec --yes --package "''${TTY_CLOCK_NPM_PACKAGE:-tty-clock@0.2.0}" -- tty-clock -config "$config_file" "$@"
  '';
}
