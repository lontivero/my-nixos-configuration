# Two-way sync of the KeePass database folder with Google Drive, via rclone.
#
#   keepass-sync init     once, by hand: authorise-check, then seed the folder
#   keepass-sync          one sync pass -- what the systemd timer runs
#   keepass-sync status    when it last ran, and whether a conflict is waiting
#
# WHY BISYNC AND NOT A MOUNT. A .kdbx is one opaque encrypted blob, and both
# ends write it: the laptop through KeePassXC, the phone through
# Keepass2Android. A FUSE mount (rclone mount, google-drive-ocamlfuse) would be
# simpler, but it leaves you with no database at all when the link is down, and
# KeePassXC saves by writing a temp file and renaming over the original, which
# is exactly the pattern FUSE layers handle worst. So: a real local file, and a
# periodic two-way reconciliation against Drive.
#
# WHY THE CREDENTIALS ARE NOT IN THE REPO. rclone keeps the Google OAuth token
# in ~/.config/rclone/rclone.conf. That token is live access to the whole
# Drive account, so it stays there as untracked state and is never referenced
# from any file in ~/.nixos. The database itself lives in ~/Sync/keepass, also
# well outside the repo. Nothing this script touches is committable, and it is
# written so that a fresh clone on a new machine simply no-ops until somebody
# runs `rclone config` and `keepass-sync init` by hand.
#
# ON CONFLICTS. Nothing here can merge two .kdbx files -- they are ciphertext,
# and byte-level merging is meaningless. What this script guarantees instead is
# that a conflict never destroys anything: `--conflict-resolve newer` lets the
# more recently written side keep the real filename, and the loser is preserved
# alongside it as passwords.kdbx.conflict1 (the number increments, so a second
# conflict cannot overwrite the record of the first). KeePassXC merges those
# properly, per entry and by timestamp, through
#
#   Database -> Merge from database...
#
# which is lossless because KDBX carries per-entry modification times. So the
# recovery drill is: open the database, merge the .conflict file into it, save,
# delete the .conflict file. A toast fires whenever one appears.

remote=${KEEPASS_REMOTE:-gdrive:keepass}
dir=${KEEPASS_DIR:-$HOME/Sync/keepass}
state=${XDG_STATE_HOME:-$HOME/.local/state}/keepass-sync
marker=$state/resynced

note() { printf 'keepass-sync: %s\n' "$*" >&2; }
toast() { notify-send --app-name=keepass-sync "$@" || true; }

# The remote's name, i.e. everything before the colon in "gdrive:keepass".
remote_name=${remote%%:*}

# Has `rclone config` been run for this remote yet? Until it has there is
# nothing to sync against, and the timer should idle quietly rather than fail
# every ten minutes -- an unconfigured machine is a normal state here, not a
# fault. listremotes prints one "name:" per line.
configured() {
  rclone listremotes | grep -qx -- "$remote_name:"
}

# Report any conflict files the last pass left behind. Named by rclone as
# <file>.conflict<n>; see the note at the top on why they are never deleted
# automatically.
conflicts() {
  local found=()
  shopt -s nullglob
  found=("$dir"/*.conflict*)
  shopt -u nullglob
  printf '%s\n' "${found[@]}"
}

do_init() {
  if ! configured; then
    note "no rclone remote called '$remote_name' yet. Run:"
    note "    rclone config"
    note "and create a Google Drive remote with that name, then run this again."
    exit 1
  fi

  # Refuse to seed on top of an existing database. --resync does not merge:
  # it declares one side authoritative and makes the other match, so pointing
  # it at a folder that already holds a .kdbx is how people lose one. Sorting
  # that out is a human decision, not something to guess at.
  mkdir -p "$dir" "$state"
  if [ -n "$(ls -A "$dir")" ]; then
    note "$dir is not empty, refusing to --resync over it."
    note "Move what is there aside, run init, then merge the copy back in"
    note "through KeePassXC's Database -> Merge from database..."
    exit 1
  fi

  rclone mkdir "$remote"
  rclone bisync "$remote" "$dir" --resync --verbose
  touch "$marker"
  note "seeded $dir from $remote; the timer takes it from here."
}

do_sync() {
  configured || { note "no rclone remote '$remote_name' configured yet; nothing to do."; exit 0; }

  # bisync cannot run without the baseline listings --resync writes, and it
  # must not be allowed to create them on the fly: it also refuses to run
  # after a failed pass, and auto-resyncing there would resolve a real error
  # by silently overwriting one side. Wait for a human instead.
  if [ ! -e "$marker" ]; then
    note "not initialised yet -- run 'keepass-sync init' once."
    exit 0
  fi

  local before after
  before=$(conflicts)

  rclone bisync "$remote" "$dir" \
    --conflict-resolve newer \
    --conflict-suffix conflict

  after=$(conflicts)
  if [ "$after" != "$before" ] && [ -n "$after" ]; then
    toast --urgency=critical "KeePass sync conflict" \
      "Both sides changed. The newer copy is in place; merge the .conflict file into it with Database -> Merge from database..."
  fi
}

do_status() {
  printf 'remote:   %s\n' "$remote"
  printf 'local:    %s\n' "$dir"

  if ! configured; then
    printf 'state:    no rclone remote "%s" -- run: rclone config\n' "$remote_name"
  elif [ ! -e "$marker" ]; then
    printf 'state:    configured, not seeded -- run: keepass-sync init\n'
  else
    printf 'state:    active since %s\n' "$(date -r "$marker" '+%Y-%m-%d %H:%M')"
  fi

  systemctl --user list-timers --no-pager keepass-sync.timer || true

  local pending
  pending=$(conflicts)
  if [ -n "$pending" ]; then
    printf '\nconflicts waiting to be merged:\n%s\n' "$pending"
  fi
}

case ${1:-sync} in
  init) do_init ;;
  sync) do_sync ;;
  status) do_status ;;
  *)
    note "usage: keepass-sync [init|sync|status]"
    exit 64
    ;;
esac
