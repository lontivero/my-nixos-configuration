# Fixed-width network throughput for waybar.
#
# The stock `network` module prints {bandwidthDownBytes}, whose rendered width
# changes with every sample ("12B" then "1.2MB" then "834kB"). waybar packs the
# right-hand group as one box, so each of those changes shoves every other
# module sideways -- once a second, forever. This prints the same two numbers
# padded to a constant four characters, so the bar geometry never moves.
#
# State lives in $XDG_RUNTIME_DIR because the rate is a delta between two polls
# and waybar re-execs this script from scratch on every interval. A missing or
# stale state file just yields 0/0 for one tick.

state="${XDG_RUNTIME_DIR:-/tmp}/waybar-netspeed.state"

# Sum rx/tx over the real interfaces. /proc/net/dev's columns are
# "iface: rx_bytes rx_packets ... tx_bytes ...", i.e. tx_bytes is the 9th
# number after the colon. lo and the virtual bridges would otherwise count
# local traffic as if it had crossed the wire.
counters=$(awk '
  NR > 2 {
    split($0, f, ":")
    iface = f[1]
    gsub(/[[:space:]]/, "", iface)
    if (iface == "lo" || iface ~ /^(docker|veth|virbr|br-|tun|tap)/) next
    split(f[2], v, " ")
    rx += v[1]
    tx += v[9]
  }
  END { printf "%d %d\n", rx, tx }
' /proc/net/dev)

now=$(date +%s)
rx=${counters% *}
tx=${counters#* }

down=0
up=0
if [ -r "$state" ]; then
  prev_t=0
  prev_rx=0
  prev_tx=0
  read -r prev_t prev_rx prev_tx < "$state" || true
  dt=$((now - prev_t))
  # The >= guards cover a counter reset, which happens whenever an interface
  # goes down and comes back; a negative delta would otherwise print garbage.
  if [ "$dt" -gt 0 ] && [ "$rx" -ge "$prev_rx" ] && [ "$tx" -ge "$prev_tx" ]; then
    down=$(((rx - prev_rx) / dt))
    up=$(((tx - prev_tx) / dt))
  fi
fi
printf '%s %s %s\n' "$now" "$rx" "$tx" > "$state"

# Always exactly four characters: at most three for the number and one for the
# unit. The number keeps a decimal only below 9.95, where "9.9K" still fits.
human() {
  awk -v v="$1" 'BEGIN {
    split("B K M G T", u, " ")
    i = 1
    while (v >= 1000 && i < 5) { v /= 1024; i++ }
    if (i > 1 && v < 9.95) r = sprintf("%.1f%s", v, u[i])
    else                   r = sprintf("%.0f%s", v, u[i])
    printf "%4s", r
  }'
}

printf '󰇚 %s 󰕒 %s\n' "$(human "$down")" "$(human "$up")"
