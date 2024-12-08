{ config, ... }:

let
  unstable = import <nixos-unstable> {
    config = {
      allowUnfree = true;
    };
  };
in
{
  boot.kernelPackages = unstable.linuxPackages_latest;

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.latest;

    ...
  };
}
