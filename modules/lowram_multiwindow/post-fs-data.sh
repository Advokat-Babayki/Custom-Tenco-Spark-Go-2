#!/system/bin/sh
# Android Go gates every multi-window form behind
# ActivityManager.isLowRamDeviceStatic(), which reads ro.config.low_ram.
# resetprop is not in PATH this early, so use the absolute path.
RP=/debug_ramdisk/resetprop
[ -x "$RP" ] || RP=/product/bin/resetprop
"$RP" -n ro.config.low_ram false
