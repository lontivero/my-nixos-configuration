# Enter a project's nix development shell, optionally running one command in
# it instead of an interactive shell:
#
#   project-devshell WalletWasabi            # a shell, as if typed by hand
#   project-devshell WalletWasabi rider .    # Rider, with the shell's env
#
# The second form is the point of this script. Rider is not installed on the
# system at all -- every project's flake puts `jetbrains.rider` in its own
# devShell, next to the dotnet-sdk that project pins -- so the IDE has to be
# started from inside the shell or it does not exist, and starting it there is
# also what gives it DOTNET_ROOT and LD_LIBRARY_PATH.
#
# NB: `nix` is deliberately NOT in this script's runtimeInputs. It comes from
# the system profile, so the client is always the one that matches the daemon
# this machine is running.

project=${1:?usage: project-devshell <project> [command ...]}
shift

cd "$HOME/Projects/$project"

# Which of the three ways in is available here, most specific first.
#
#   devshell    a `nix develop --profile devshell` gcroot, as created below.
#               Entering through it skips flake evaluation entirely, so the
#               shell opens more or less instantly and -- because it is a
#               gcroot -- survives `nix-collect-garbage`. This is the fast
#               path and the one every project here should end up on.
#   flake.nix   no profile yet: create it on this first run, so the next one
#               takes the fast path. NB: this writes `devshell` and
#               `devshell-1-link` into the working tree; NScheme's .gitignore
#               already covers them, the others may want the same two lines.
#   shell.nix   pre-flake project (nbitcoin).
#
if [ -e devshell ]; then
  enter=(nix develop ./devshell)
elif [ -e flake.nix ]; then
  enter=(nix develop --profile devshell)
elif [ -e shell.nix ]; then
  enter=(nix-shell)
else
  # Not a nix project. Still honour the request rather than failing: the
  # directory is what was asked for, the shell around it is a detail.
  if [ "$#" -eq 0 ]; then exec "${SHELL:-bash}"; fi
  exec "$@"
fi

if [ "$#" -eq 0 ]; then
  exec "${enter[@]}"
fi

# `nix develop --command` takes the command as separate arguments; nix-shell's
# --run takes one string it hands to bash. "$*" is good enough for the second
# because the only caller passes `rider .`, and no path under ~/Projects has a
# space in it.
case ${enter[0]} in
  nix-shell) exec "${enter[@]}" --run "$*" ;;
  *) exec "${enter[@]}" --command "$@" ;;
esac
