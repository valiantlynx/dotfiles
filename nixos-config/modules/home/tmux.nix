{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    clock24 = true;
    newSession = true;
    # Force tmux to use /tmp for sockets (WSL2 compat)
    secureSocket = false;
  };
}
