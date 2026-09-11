# NVIDIA + AMD PRIME render offload for this desktop.
# The bus IDs below are specific to this machine; check them with `lspci`.
{ config, pkgs, ... }:
{
  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver.displayManager.sessionCommands = ''
    # Link NVIDIA (provider 1) outputs to AMD (provider 0)
    ${pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource 1 0
    ${pkgs.xorg.xrandr}/bin/xrandr --auto
  '';

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    open = false;
    nvidiaSettings = true;
    powerManagement.enable = true;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      nvidiaBusId = "PCI:1:0:0";
      amdgpuBusId = "PCI:5:0:0";
    };
  };
}
