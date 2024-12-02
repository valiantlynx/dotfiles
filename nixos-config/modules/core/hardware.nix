{ pkgs, ... }:
{
  hardware = {
    graphics = {
      enable = true;
      extraPackages = with pkgs; [

      ];
    };
    bluetooth = {
      enable = true; # enables support for Bluetooth
      powerOnBoot = true; # powers up the default Bluetooth controller on boot
    };
  };
  services.blueman.enable = true;
  hardware.enableRedistributableFirmware = true;
}
