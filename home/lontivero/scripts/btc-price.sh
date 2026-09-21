# Bitcoin spot price for waybar, as a JSON module (text/tooltip/class).
#
# Kraken's public ticker is the source: no key, no rate limit worth worrying
# about at one call per ten minutes, and it returns the 24h open/high/low in
# the same response, so the colour and the tooltip come for free. Coinbase is
# the fallback for the case where Kraken is down or blocked.
#
# The last good answer is cached in $XDG_RUNTIME_DIR. A failed poll then keeps
# showing that number with a "stale" class rather than blanking the module --
# a ten-minute interval means a blank would sit there for ten minutes.

cache="${XDG_RUNTIME_DIR:-/tmp}/waybar-btc.json"

price=""
open=""
high=""
low=""
source=""

kraken=$(curl -sf --max-time 15 'https://api.kraken.com/0/public/Ticker?pair=XBTUSD' || true)
if [ -n "$kraken" ]; then
  # The result key is the canonical pair name (XXBTZUSD), not what was asked
  # for, so take the first entry rather than naming it. One jq call per field
  # is four calls every ten minutes -- cheaper than making `read` and `set -e`
  # agree about what an empty reply means.
  kfield() { printf "%s" "$kraken" | jq -r "first(.result[]) | $1" 2>/dev/null || true; }
  price=$(kfield ".c[0]")
  open=$(kfield ".o")
  high=$(kfield ".h[1]")
  low=$(kfield ".l[1]")
  source="Kraken"
fi

case "$price" in
  '' | null)
    coinbase=$(curl -sf --max-time 15 'https://api.coinbase.com/v2/prices/BTC-USD/spot' || true)
    price=$(printf '%s' "$coinbase" | jq -r '.data.amount // empty' 2>/dev/null || true)
    open=""
    source="Coinbase"
    ;;
esac

stale=no
case "$price" in
  '' | null)
    if [ -r "$cache" ]; then
      price=$(jq -r '.price // empty' < "$cache" 2>/dev/null || true)
      open=$(jq -r '.open // empty' < "$cache" 2>/dev/null || true)
      source=$(jq -r '.source // "cache"' < "$cache" 2>/dev/null || true)
      stale=yes
    fi
    ;;
  *)
    jq -cn --arg p "$price" --arg o "$open" --arg s "$source" \
      '{price: $p, open: $o, source: $s}' > "$cache"
    ;;
esac

if [ -z "$price" ]; then
  # Never polled successfully and nothing cached: say so instead of lying.
  jq -cn '{text: "󰠓   --", tooltip: "bitcoin price unavailable", class: "stale"}'
  exit 0
fi

# Whole dollars with thousands separators: 77370.40000 -> 77,370.
money() {
  awk -v p="$1" 'BEGIN {
    n = sprintf("%.0f", p)
    out = ""
    while (length(n) > 3) {
      out = "," substr(n, length(n) - 2) out
      n = substr(n, 1, length(n) - 3)
    }
    print n out
  }'
}

# Padded to a fixed seven-character field, so this module does not do to the
# bar what the network module used to -- see netspeed.sh for that story. Seven
# covers every price from 1,000 to 999,999; the day a bitcoin costs a million
# dollars the module widens by two characters once and then stays put.
text=$(printf "%7s" "$(money "$price")")

class=flat
change=""
if [ -n "$open" ] && [ "$open" != "null" ] && [ "$open" != "0" ]; then
  change=$(awk -v p="$price" -v o="$open" 'BEGIN { printf "%+.2f%%", (p - o) / o * 100 }')
  case "$change" in
    -*) class=down ;;
    *)  class=up ;;
  esac
fi
[ "$stale" = yes ] && class=stale

tooltip="<b>BTC/USD  $(printf '%s' "$text" | tr -d ' ')</b>"
[ -n "$change" ] && tooltip="$tooltip
24h change   $change"
[ -n "$high" ] && [ "$high" != "null" ] && tooltip="$tooltip
24h high     $(money "$high")
24h low      $(money "$low")"
tooltip="$tooltip
source       $source, $(date '+%H:%M')"
[ "$stale" = yes ] && tooltip="$tooltip (poll failed, showing cached)"

jq -cn --arg text "󰠓 $text" --arg tooltip "$tooltip" --arg class "$class" \
  '{text: $text, tooltip: $tooltip, class: $class}'
