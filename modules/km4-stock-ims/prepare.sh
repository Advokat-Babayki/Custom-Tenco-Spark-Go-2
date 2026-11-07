#!/usr/bin/env bash
# Достаёт стоковые IMS-файлы с подключённого телефона в модуль.
# Требуется стоковый system_ext — на GSI он остаётся нетронутым.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/system/system_ext"

command -v adb >/dev/null || { echo "adb не найден" >&2; exit 1; }

pull() { mkdir -p "$OUT/$(dirname "$2")"; adb pull "/system/system_ext/$1" "$OUT/$2" >/dev/null; echo "  $1"; }

echo "Копирую из /system/system_ext:"
pull priv-app/ims/ims.apk                          priv-app/ims/ims.apk
pull priv-app/ims/lib/arm64/libn3am_jni.so         priv-app/ims/lib/arm64/libn3am_jni.so
pull lib64/libimsbrd.so                            lib64/libimsbrd.so
pull lib64/libn3am_jni.so                          lib64/libn3am_jni.so
pull lib/libimsbrd.so                              lib/libimsbrd.so
pull lib/libn3am_jni.so                            lib/libn3am_jni.so
pull bin/ims_bridged                               bin/ims_bridged
pull etc/permissions/com.spreadtrum.ims.xml        etc/permissions/com.spreadtrum.ims.xml
pull etc/init/ims_bridged.rc                       etc/init/ims_bridged.rc

chmod 0755 "$OUT/bin/ims_bridged"
echo "Готово: $OUT"
echo "Теперь: bash scripts/install-modules.sh km4-stock-ims"
