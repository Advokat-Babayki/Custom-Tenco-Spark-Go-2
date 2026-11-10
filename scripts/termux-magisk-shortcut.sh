#!/data/data/com.termux/files/usr/bin/bash
# Magisk shortcut: unhide, open, wait until focus leaves, hide again.
# Install to ~/.shortcuts/Magisk, then add a Termux:Widget shortcut.
su -c "pm unhide com.topjohnwu.magisk"
su -c "am start -n com.topjohnwu.magisk/.ui.MainActivity" >/dev/null 2>&1

i=0
until su -c "dumpsys window" 2>/dev/null | grep -q "mCurrentFocus=.*com.topjohnwu.magisk"; do
    i=$((i + 1))
    [ "$i" -ge 20 ] && break
    sleep 1
done

while su -c "dumpsys window" 2>/dev/null | grep -q "mCurrentFocus=.*com.topjohnwu.magisk"; do
    sleep 2
done

su -c "pm hide com.topjohnwu.magisk"
