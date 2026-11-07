#!/system/bin/sh
D=/data/adb/modules/brightness_scale
W=/sys/class/backlight/sprd_backlight/brightness
# fix whatever the HAL left at boot, then react to every HAL write
sh $D/handler.sh
exec inotifyd $D/handler.sh $W:w
