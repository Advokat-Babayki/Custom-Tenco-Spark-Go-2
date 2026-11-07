#!/usr/bin/env bash
# Ставит модули из modules/ на подключённый телефон (нужен root).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/modules"

command -v adb >/dev/null || { echo "adb не найден" >&2; exit 1; }

[ "$#" -gt 0 ] && MODULES=("$@") || MODULES=($(ls "$SRC"))

for name in "${MODULES[@]}"; do
    dir="$SRC/$name"
    [ -d "$dir" ] || { echo "нет модуля $name" >&2; continue; }

    # у pocketmode модуль лежит в подкаталоге module/
    [ -f "$dir/module/module.prop" ] && dir="$dir/module"
    [ -f "$dir/module.prop" ] || { echo "пропуск $name: нет module.prop" >&2; continue; }

    if [ "$name" = "km4-stock-ims" ] && [ ! -f "$dir/system/system_ext/priv-app/ims/ims.apk" ]; then
        echo "пропуск $name: сначала запустите modules/km4-stock-ims/prepare.sh" >&2
        continue
    fi

    echo "-> $name"
    adb push "$dir" /data/local/tmp/module >/dev/null
    adb shell su -c "rm -rf /data/adb/modules/$name && cp -r /data/local/tmp/module /data/adb/modules/$name && chmod -R 0755 /data/adb/modules/$name"
    adb shell su -c "rm -rf /data/local/tmp/module"
done

echo "Готово. Перезагрузите телефон: adb reboot"
