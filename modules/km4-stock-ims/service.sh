#!/system/bin/sh
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done

resetprop -n persist.vendor.sys.volte.enable true
resetprop -n persist.vendor.sys.single.imsstack true
resetprop -n persist.ims.apn ims

pm enable com.spreadtrum.ims 2>/dev/null

cmd overlay enable me.phh.treble.overlay.sprdims_telephony 2>/dev/null
cmd overlay disable me.phh.treble.overlay.flossims_telephony 2>/dev/null

if [ "$(getprop init.svc.ims_bridged)" != "running" ] && [ -x /system/system_ext/bin/ims_bridged ]; then
    nohup /system/system_ext/bin/ims_bridged >/dev/null 2>&1 &
fi

magiskpolicy --live "allow system_server priv_app binder { call transfer }"
magiskpolicy --live "allow system_server priv_app fd use"
magiskpolicy --live "allow system_server priv_app process getattr"
magiskpolicy --live "allow priv_app radio binder { call transfer }"
magiskpolicy --live "allow priv_app radio fd use"
magiskpolicy --live "allow priv_app radio process getattr"
magiskpolicy --live "allow priv_app ext_radio_service service_manager find"
magiskpolicy --live "allow priv_app default_android_service service_manager find"
magiskpolicy --live "allow priv_app rild binder { call transfer }"
magiskpolicy --live "allow priv_app radio_prop property_service set"
magiskpolicy --live "allow priv_app property_socket sock_file write"
magiskpolicy --live "allow rild priv_app binder { call transfer }"
magiskpolicy --live "allow rild priv_app fd use"

log -t KM4-IMS "Stock KM4 IMS applied; SELinux remains enforcing and network mode is unchanged"
