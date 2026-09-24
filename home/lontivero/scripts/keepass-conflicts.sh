# Notice when Syncthing has left a conflicting copy of the database behind, and
# say so loudly enough that it gets merged rather than sat on for a month.
#
#   keepass-conflicts          check, and toast if the set of conflicts changed
#   keepass-conflicts list     print them and exit 1 if there are any
#
# WHY THIS EXISTS. Syncthing reconciles files, and a .kdbx is ciphertext: when
# both ends change it between syncs there is no byte-level merge to do. What
# Syncthing does instead is keep both -- the winner under the real name, the
# loser renamed to passwords.sync-conflict-20260924-134500-ABCDEFG.kdbx -- and
# then say nothing about it. Nothing is lost at that point, but nothing is
# resolved either, and the entries you added on the losing side are invisible
# until someone opens that file. Hence the toast.
#
# The fix, once toasted, is KeePassXC's
#
#   Database -> Merge from database...
#
# pointed at the conflict file. That IS a real merge: KDBX carries a
# modification time per entry, so the two histories interleave correctly rather
# than one clobbering the other. Save, then delete the conflict file.
#
# NB: the directory's mtime changes on every save KeePassXC makes, so the path
# unit driving this fires constantly. Re-toasting the same conflict every time
# would train you to ignore it, so the set of conflict files is remembered
# between runs and only a CHANGE to that set is worth interrupting for.

dir=${KEEPASS_DIR:-$HOME/Sync/keepass}
state=${XDG_STATE_HOME:-$HOME/.local/state}/keepass-conflicts
stamp=$state/notified

# Syncthing's naming is <base>.sync-conflict-<date>-<time>-<device>.<ext>.
current() {
  local found=()
  shopt -s nullglob
  found=("$dir"/*.sync-conflict-*)
  shopt -u nullglob
  printf '%s\n' "${found[@]}" | sort
}

now=$(current)

case ${1:-check} in
  list)
    if [ -z "$now" ]; then
      printf 'no conflicts in %s\n' "$dir"
      exit 0
    fi
    printf '%s\n' "$now"
    exit 1
    ;;

  check)
    mkdir -p "$state"
    before=""
    [ -e "$stamp" ] && before=$(cat "$stamp")

    # Record first, notify second: a toast that fails (no notification daemon
    # yet, early in the session) must not mean the same one fires forever.
    printf '%s' "$now" > "$stamp"

    if [ -n "$now" ] && [ "$now" != "$before" ]; then
      notify-send --app-name=keepass --urgency=critical \
        "KeePass database conflict" \
        "Both ends changed it. Merge the sync-conflict copy in with Database -> Merge from database..." || true
    fi
    ;;

  *)
    printf 'usage: keepass-conflicts [check|list]\n' >&2
    exit 64
    ;;
esac
