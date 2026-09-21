# gossip, the desktop nostr client, plus the one patch it needs to start.
#
# 0.14.0 refuses to start once a malformed tag lands in the stored bookmark
# list. gossip_lib::init() parses that event before anything else runs, and a
# tag it cannot parse aborts the process with
#
#     Error: Error { kind: Nostr(TagMismatch), file: None, line: None }
#
# Here the tag was ["title", ""], which gossip would have ignored anyway. The
# UI never opens, and neither do the subcommands that could repair the
# database, because init() runs before the arguments are handled -- so the
# only way out is to patch it or throw the profile away. The patch turns the
# bad tag into a warning and skips it, matching how add_tags already treats
# the tag kinds it doesn't support.
#
# Reported and fixed upstream in PR #1036; drop the patch once that lands:
#   https://github.com/mikedilger/gossip/pull/1036
{ pkgs, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      gossip = prev.gossip.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          ./patches/gossip-skip-unparseable-bookmark-tags.patch
        ];

        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.makeWrapper ];

        # gossip configures tracing from RUST_LOG and defaults it to "info",
        # which is why the crash above arrived as a single line with no
        # context. Raise gossip's own crates to debug -- and only those, so
        # the websocket and TLS stacks don't bury the interesting output.
        # RUST_LOG is only a default here, so `RUST_LOG=trace gossip` still
        # wins, and no other Rust program on the system is affected.
        #
        # Appended to postFixup rather than postInstall because postFixup
        # patchelfs $out/bin/gossip, which has to happen while it is still an
        # ELF binary and not yet a wrapper script.
        postFixup = (old.postFixup or "") + ''
          wrapProgram $out/bin/gossip \
            --set-default RUST_LOG "info,gossip=debug,gossip_lib=debug,nostr_types=debug"
        '';
      });
    })
  ];

  environment.systemPackages = [ pkgs.gossip ];
}
