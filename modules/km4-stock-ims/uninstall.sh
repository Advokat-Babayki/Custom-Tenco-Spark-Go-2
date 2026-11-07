#!/system/bin/sh
resetprop --delete persist.vendor.sys.volte.enable
resetprop --delete persist.vendor.sys.single.imsstack
resetprop --delete persist.ims.apn
cmd overlay disable me.phh.treble.overlay.sprdims_telephony 2>/dev/null
