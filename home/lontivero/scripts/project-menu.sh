# The project picker ($mod+o) and the project switcher ($mod+i).
#
#   project-menu open      pick any project; start it, or focus it if it is up
#   project-menu switch    pick from the projects that are already up
#
# ONE PROJECT, ONE WORKSPACE. Each project gets a Hyprland workspace named
# after its directory -- "Nostra", "WalletWasabi" -- holding a terminal sitting
# in its devshell and the Rider window started from that same shell. Working on
# several projects at once is then just several workspaces, and switching
# project is switching workspace, so everything that already understands
# workspaces (waybar's module, $mod+Tab, the swipe gesture) understands
# projects for free.
#
# Named workspaces cannot collide with the numbered ones on $mod+1..0: Hyprland
# keys those by id and these by name, and waybar's sort-by-number lists the
# named ones after the numbered ones.

projects_root="$HOME/Projects"

# Every immediate subdirectory of ~/Projects that is a git checkout. Others/
# holds clones of other people's repositories and is not a checkout itself, so
# it drops out of this on its own -- it is named anyway so that stays a
# decision rather than an accident.
projects() {
  local path name
  for path in "$projects_root"/*; do
    name=$(basename "$path")
    if [ "$name" = Others ]; then continue; fi
    # -e, not -d: a worktree's .git is a file.
    if [ ! -e "$path/.git" ]; then continue; fi
    printf '%s\n' "$name"
  done
}

# The names of every workspace that currently exists. Hyprland destroys an
# empty workspace as soon as focus leaves it, so a project's name appearing
# here means that project still has windows open.
workspaces() {
  hyprctl -j workspaces | jq -r '.[].name'
}

# The projects that are up: the intersection of the two lists above.
running() {
  comm -12 <(projects | sort) <(workspaces | sort)
}

# rofi in dmenu mode. It answers with the INDEX of the chosen row (-format i)
# rather than its text, because the rows carry a marker for the projects that
# are already running and stripping that back off to recover a name is fiddly
# for no reason. A cancelled menu exits non-zero; a typed-in line that matches
# nothing comes back as -1.
menu() {
  rofi -dmenu -i -p "$1" -format i
}

start() {
  local name=$1 already=no

  # Ask before dispatching: focusing a workspace is what brings it into
  # existence, so after the dispatch below every name looks like it was
  # already running.
  if workspaces | grep -qxF "$name"; then already=yes; fi

  hyprctl dispatch workspace "name:$name"
  if [ "$already" = yes ]; then return; fi

  notify-send --app-name=project "$name" "Opening the devshell and Rider."

  # The absolute store paths, resolved here rather than written into the exec
  # lines below as bare names. Hyprland runs an exec through /bin/sh with the
  # session's PATH, and greetd starts the session without going through a login
  # shell -- so ~/.nix-profile/bin is not reliably on it. `command -v` finds
  # them on THIS script's PATH, which writeShellApplication built from its
  # runtimeInputs and is therefore not in doubt.
  local devshell term
  devshell=$(command -v project-devshell)
  term=$(command -v alacritty)

  # `[workspace name:X silent]` pins each window to this project's workspace
  # even if focus has moved on by the time it maps, which matters: Rider takes
  # the better part of a minute to show up on a cold devshell. "silent" stops
  # Hyprland following the window over when it does.
  #
  # NB: --class devshell, not the default. The window rules in hyprland.nix
  # send class ^([Aa]lacritty)$ to workspace 1, and a project terminal that
  # teleported off its own workspace would defeat the whole arrangement.
  hyprctl dispatch exec \
    "[workspace name:$name silent] $term --class devshell --title '$name devshell' -e $devshell $name"
  hyprctl dispatch exec \
    "[workspace name:$name silent] $devshell $name rider ."
}

case ${1:-open} in
  open)
    mapfile -t names < <(projects)
    if [ "${#names[@]}" -eq 0 ]; then
      notify-send --app-name=project "No projects" "Nothing in $projects_root is a git checkout."
      exit 0
    fi

    mapfile -t up < <(running)
    rows=()
    for name in "${names[@]}"; do
      # U+25CF/U+25CB rather than the Nerd Font circles: these are plain
      # Unicode, so they survive every editor and pipe they pass through.
      if printf '%s\n' "${up[@]}" | grep -qxF "$name"; then
        rows+=("● $name")
      else
        rows+=("○ $name")
      fi
    done

    idx=$(printf '%s\n' "${rows[@]}" | menu project) || exit 0
    if [ "$idx" -lt 0 ]; then exit 0; fi
    start "${names[$idx]}"
    ;;

  switch)
    mapfile -t names < <(running)
    if [ "${#names[@]}" -eq 0 ]; then
      notify-send --app-name=project "No project open" "Start one with Super+o."
      exit 0
    fi

    idx=$(printf '%s\n' "${names[@]}" | menu switch) || exit 0
    if [ "$idx" -lt 0 ]; then exit 0; fi
    hyprctl dispatch workspace "name:${names[$idx]}"
    ;;

  *)
    printf 'usage: project-menu [open|switch]\n' >&2
    exit 1
    ;;
esac
