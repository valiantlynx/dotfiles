{
  inputs,
  nixpkgs,
  self,
  username,
  host,
  ...
}:
{
  # Allow insecure packages globally
  nixpkgs.config.permittedInsecurePackages = [
    "electron-27.3.11"
  ];

  imports = [
    ./bootloader.nix
    ./hardware.nix
    ./xserver.nix
    ./network.nix
    ./nh.nix
    ./pipewire.nix
    ./program.nix
    ./security.nix
    ./services.nix
    ./steam.nix
    ./system.nix
    ./flatpak.nix
    ./user.nix
    ./wayland.nix
    ./virtualization.nix
  ];
}
