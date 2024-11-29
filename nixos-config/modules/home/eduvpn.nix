{ pkgs, ... }:
{
  home.packages = (with pkgs; [ eduvpn-client ]);
}
