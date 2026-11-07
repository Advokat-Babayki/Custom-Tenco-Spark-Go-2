#!/usr/bin/env bash
# Read-only проверка: то ли устройство подключено.
set -uo pipefail

fail=0
ok()   { printf '  ok   %s\n' "$*"; }
bad()  { printf '  FAIL %s\n' "$*"; fail=1; }
warn() { printf '  warn %s\n' "$*"; }

command -v adb >/dev/null || { echo "adb не найден"; exit 1; }
[ "$(adb devices | grep -c 'device$')" -ge 1 ] || { echo "нет подключённого устройства"; exit 1; }

prop() { adb shell getprop "$1" 2>/dev/null | tr -d '\r'; }

echo "Устройство:"
for p in ro.product.model ro.product.device ro.boot.hardware ro.build.version.release \
         ro.build.display.id ro.build.fingerprint ro.boot.slot_suffix \
         ro.boot.verifiedbootstate ro.boot.flash.locked ro.boot.vbmeta.device_state \
         ro.boot.veritymode ro.boot.dynamic_partitions ro.vndk.version; do
    printf '  %-32s %s\n' "$p" "$(prop "$p")"
done

echo "Проверки:"
[ "$(prop ro.product.model)" = "TECNO KM4" ] && ok "модель TECNO KM4" || bad "модель не TECNO KM4"
[ "$(prop ro.boot.hardware)" = "ums9230_KM4_go" ] && ok "hardware ums9230_KM4_go" || bad "другой hardware"
[ "$(prop ro.boot.flash.locked)" = "0" ] && ok "загрузчик разблокирован" || bad "загрузчик заблокирован — см. docs/root.md"
[ "$(prop ro.boot.dynamic_partitions)" = "true" ] && ok "dynamic partitions" || bad "нет dynamic partitions"

build="$(prop ro.build.display.id)"
case "$build" in
    *180*|*19*) ok "сборка $build" ;;
    *) warn "сборка $build: убедитесь, что она не ниже 180010" ;;
esac

command -v fastboot >/dev/null && ok "fastboot есть" || bad "fastboot не найден"

exit "$fail"
