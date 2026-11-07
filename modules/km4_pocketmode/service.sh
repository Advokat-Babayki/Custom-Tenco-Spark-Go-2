#!/system/bin/sh

while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done

PKG=dev.km4.pocketmode

i=0
while [ $i -lt 30 ]; do
    if pm path "$PKG" >/dev/null 2>&1; then
        break
    fi
    i=$((i + 1))
    sleep 1
done

cmd appops set "$PKG" SYSTEM_ALERT_WINDOW allow 2>/dev/null
pm enable "$PKG" >/dev/null 2>&1
dumpsys deviceidle whitelist +"$PKG" >/dev/null 2>&1
am broadcast -a dev.km4.pocketmode.START -n "$PKG/.BootReceiver" --user 0 >/dev/null 2>&1

log -t KM4-PocketMode "service started"
