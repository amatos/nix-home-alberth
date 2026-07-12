{
  pkgs,
  nix-secrets,
  ...
}:

let
  userDefs = import ../users.nix;
  inherit (userDefs) primaryUser;
in
{
  imports = [
    ./common/atuin.nix
    ./common/cachix.nix
    ./common/chezmoi.nix
    ./common/devenv.nix
    ./common/git.nix
    ./common/gpg.nix
    ./common/latexmk.nix
    ./common/packages.nix
    ./common/shells.nix
    ./common/ssh.nix
    ./common/starship.nix
    ./common/stylix.nix
    ./common/theming.nix
    ./common/tools.nix
    ./common/zed.nix
  ];

  home.username = primaryUser;
  home.homeDirectory =
    if pkgs.stdenv.isDarwin then "/Users/${primaryUser}" else "/home/${primaryUser}";

  # Let home-manager manage itself
  programs.home-manager.enable = true;

  # Man pages with pre-built cache for fast `man -k` lookups
  programs.man = {
    enable = true;
    generateCaches = false;
  };

  # XDG base directories — moves config, cache, and data out of ~
  xdg.enable = true;

  # age identity — symlinked to the canonical location so ragenix and age tools
  # find it without requiring an explicit -i flag (via the shell alias in shells.nix).
  home.file.".config/age/yubikey-identity.txt".source =
    "${nix-secrets}/age-yubikey-identity-d43f4e92.txt";

  home.file.".local/bin/npbs-all" = {
    source = ./scripts/npbs-all.sh;
    executable = true;
  };

  # "$ somecommand" copy-paste guard — strips a leading "$" and runs the rest.
  home.file.".local/bin/$" = {
    source = ./scripts/dollar.sh;
    executable = true;
  };

  # extract <file> — archive extraction/mounting dispatcher.
  home.file.".local/bin/extract" = {
    source = ./scripts/extract.sh;
    executable = true;
  };

  # update-flake.py [input] — used by the nixflakeup alias (shells.nix).
  home.file.".local/bin/update-flake.py" = {
    source = ./scripts/update-flake.py;
    executable = true;
  };

  # .editorconfig — https://editorconfig.org
  home.file.".editorconfig".text = ''
    # EditorConfig is awesome: https://editorconfig.org

    # top-most EditorConfig file
    root = true

    # Unix-style newlines with a newline ending every file
    [*]
    end_of_line = lf
    insert_final_newline = true

    # Default 2 space indentation
    [*]
    indent_style = space
    indent_size = 2

    # 4 space indentation
    [*.py]
    indent_style = space
    indent_size = 4

    # Tab indentation (no size specified)
    [Makefile]
    indent_style = tab
  '';

  # Environment variables applied to all shells
  home.sessionVariables = {
    ALTERNATE_EDITOR = "";
    EDITOR = "nvim";
    VISUAL = "zed -w";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    CLICOLOR = "1";
  };

  home.stateVersion = "26.05";
}
