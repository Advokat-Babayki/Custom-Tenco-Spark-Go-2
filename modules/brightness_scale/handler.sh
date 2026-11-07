#!/system/bin/sh
# One write on the backlight node. The vendor lights HAL writes the raw Android
# slider value (0-255) into a 0-5119 node, so the top of the slider is 5% of
# the panel and the bottom is black. 0 means the panel was blanked: leave it.
W=/sys/class/backlight/sprd_backlight/brightness
MAX=5119
FLOOR=300
v=$(cat $W 2>/dev/null)
case "$v" in ''|*[!0-9]*) exit 0;; esac
[ "$v" -ge 1 ] && [ "$v" -le 255 ] || exit 0
a=$(settings get system screen_brightness 2>/dev/null)
case "$a" in ''|null|*[!0-9]*) a=$v;; esac
[ "$a" -gt 255 ] && a=255
[ "$a" -lt 1 ] && a=$v
want=$(( a * MAX / 255 ))
[ "$want" -lt "$FLOOR" ] && [ "$a" -gt 0 ] && want=$FLOOR
echo $want > $W 2>/dev/null
