{ pkgs, ... }:

{
  # eza (modern ls replacement)
  programs.eza = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    icons = "auto";
    git = true;
    extraOptions = [ "--header" ];
  };

  # fzf with shell integrations
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  # bat — cat clone with syntax highlighting; Dracula theme via stylix.
  programs.bat = {
    enable = true;
    config.italic-text = "always";
  };

  # btop — resource monitor
  programs.btop.enable = true;

  # tealdeer (tldr client) with auto-update
  programs.tealdeer = {
    enable = true;
    settings.updates.auto_update = true;
  };

  # zoxide — smarter cd, aliased to cd across all shells
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    options = [ "--cmd cd" ];
  };

  # direnv with nix-direnv — shell hook integration is handled by
  # direnv-instant below instead, so disabled here to avoid double-hooking.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableBashIntegration = false;
    enableZshIntegration = false;
    enableFishIntegration = false;
    enableNushellIntegration = false;
  };

  # direnv-instant — non-blocking shell hook (runs direnv in a background
  # daemon so the prompt returns immediately); replaces programs.direnv's
  # own hook integration above. Defaults enable bash/zsh/fish/nushell hooks.
  programs.direnv-instant.enable = true;

  # Nushell
  programs.nushell.enable = true;

  # tmux
  programs.tmux = {
    enable = true;
    mouse = true;
    escapeTime = 0;
    historyLimit = 50000;
    terminal = "tmux-256color";
    plugins = with pkgs.tmuxPlugins; [
      dracula
    ];
    extraConfig = ''
      set -ag terminal-overrides ",xterm-256color:RGB"
    '';
  };
}
