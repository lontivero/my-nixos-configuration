# NVIDIA + AMD PRIME render offload for this laptop (Dell G15 5515).
#
# Display wiring, which the Hyprland config in home/lontivero/hyprland.nix
# depends on: the internal eDP-1 panel hangs off the AMD iGPU (PCI 5:0:0)
# and HDMI-A-1 hangs off the NVIDIA dGPU (PCI 1:0:0).
# The bus IDs below are specific to this machine; check them with `lspci`.
{ config, pkgs, ... }:
{
  services.xserver.videoDrivers = [ "nvidia" ];
  # NB: lightdm sets one session-wrapper for the whole seat, so this runs for
  # EVERY session it starts -- the Hyprland one included, where it logged two
  # "Can't open display" lines before the compositor even spoke. Guarded on
  # DISPLAY so it stays what it is meant to be: X11-only PRIME plumbing.
  services.xserver.displayManager.sessionCommands = ''
    if [ -n "$DISPLAY" ]; then
      # Link NVIDIA (provider 1) outputs to AMD (provider 0)
      ${pkgs.xrandr}/bin/xrandr --setprovideroutputsource 1 0
      ${pkgs.xrandr}/bin/xrandr --auto
    fi
  '';

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
