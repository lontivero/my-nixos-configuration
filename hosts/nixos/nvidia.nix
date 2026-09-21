# NVIDIA + AMD PRIME render offload for this laptop (Dell G15 5515).
#
# Display wiring, which the Hyprland config in home/lontivero/hyprland.nix
# depends on: the internal eDP-1 panel hangs off the AMD iGPU (PCI 5:0:0)
# and HDMI-A-1 hangs off the NVIDIA dGPU (PCI 1:0:0).
# The bus IDs below are specific to this machine; check them with `lspci`.
{ config, pkgs, ... }:
{
  services.xserver.videoDrivers = [ "nvidia" ];
  # NB: videoDrivers is not an X11 setting despite the name -- with no X
  # server left it is still what makes the nvidia module build its kernel
  # modules and wire up the Wayland bits below. A sessionCommands hook used
  # to sit here running `xrandr --setprovideroutputsource 1 0` to link the
  # NVIDIA outputs to the AMD provider; that was PRIME plumbing for the X11
  # session and went with it. Hyprland drives both cards directly.

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    open = false;
    nvidiaSettings = true;
    powerManagement.enable = true;

    # Required for Wayland: without KMS the compositor cannot drive the
    # NVIDIA-attached HDMI output at all. Already implied by prime.offload,
    # stated here because the Hyprland session depends on it.
    modesetting.enable = true;
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
