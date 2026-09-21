# Fixed-width unread-notification counter for waybar.
#
# `swaync-client --subscribe-waybar` streams one JSON object per notification
# event and then blocks, so this is a continuous module rather than a polled
# one -- the count updates the instant a notification arrives or is cleared,
# with no interval to tune. Its output looks like:
#
#   {"text": "3", "alt": "notification", "tooltip": "", "class": "notification"}
#
# with alt/class being none | notification, optionally prefixed with dnd- and
# inhibited- when do-not-disturb or an inhibitor is active.
#
# "class" is the odd one out: while the panel itself is open swaync sends it
# as ["notification", "cc-open"] rather than a string. waybar accepts either,
# so it is passed through untouched and waybar.nix styles .cc-open.
#
# Two things are wrong with feeding that to waybar directly. The count is
# printed unpadded, and waybar packs the right-hand group as one box, so the
# bar would shift sideways every time the count crossed 9 -- the same problem
# netspeed.sh exists to avoid. And the tooltip is empty. So the stream is
# rewritten on the way through: the count right-aligned in two characters (a
# count above 99 is pinned at 99; the exact number stops being interesting
# long before that) and a tooltip built from the count and the dnd state.
#
# --unbuffered matters: without it jq holds the line until its output buffer
# fills, and the bar would only catch up every umpteenth notification.

swaync-client --subscribe-waybar | jq --unbuffered --compact-output '
  (.text | tonumber) as $n
  | (if $n > 99 then 99 else $n end | tostring) as $shown
  | {
      text: (if ($shown | length) < 2 then " " + $shown else $shown end),
      alt: .alt,
      class: .class,
      tooltip: (
        (if $n == 0 then "No new notifications"
         elif $n == 1 then "1 notification"
         else "\($n) notifications" end)
        + (if (.alt | startswith("dnd")) then "  ·  do not disturb" else "" end)
        + "\nClick to open  ·  right-click for do not disturb"
      )
    }
'
