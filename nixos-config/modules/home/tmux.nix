{ config, pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    shortcut = "m";
    escapeTime = 0;
    keyMode = "vi";
    terminal = "screen-256color";
    historyLimit = 1000000;

    extraConfig = ''
      # Terminal settings
      set-option -sa terminal-overrides ",xterm*:Tc"
      set -g default-terminal "screen-256color"
      set -g terminal-overrides ',xterm-256color:RGB'

      # Mouse and indexing
      set -g mouse on
      set -g base-index 1
      set -g pane-base-index 1
      setw -g pane-base-index 1
      set -g renumber-windows on

      # Styling
      set -g pane-active-border-style 'fg=magenta,bg=default'
      set -g pane-border-style 'fg=brightblack,bg=default'

      # Status bar
      set -g status-position top
      set -g status-interval 1

      # History
      set -g history-limit 1000000

      # Key bindings
      bind-key -n Home send Escape "OH"
      bind-key -n End send Escape "OF"
    '';
  };
}
