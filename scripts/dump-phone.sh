#!/usr/bin/env bash
# Аварийный дамп телефона через BootROM (BROM). ТОЛЬКО ЧТЕНИЕ.
#
# Пишет на ноутбук ровно то, что просили: super и metadata.
# В телефон не отправляется ни одной команды записи: только exec FDL и read_part.
#
# Запуск (BROM требует root на USB):
#   sudo bash scripts/dump-phone.sh [--tools DIR] [--out DIR]
#
# Телефон: выключить, зажать Volume+ и Volume−, подключить USB.
# Интернет на это время не нужен — скрипт полностью локальный.
set -uo pipefail

TOOLS="$(cd "$(dirname "$0")/.." && pwd)/../TECNO_KM4_RECON/tools"
OUT=""
SUPER_BYTES=9521070080

while [ $# -gt 0 ]; do
    case "$1" in
        --tools) TOOLS="$2"; shift 2 ;;
        --out)   OUT="$2";   shift 2 ;;
        *) echo "неизвестный аргумент: $1" >&2; exit 2 ;;
    esac
done

SPD="$TOOLS/spd_dump"
FDL1="$TOOLS/fdl_kl4/fdl1-dl.bin"
FDL2="$TOOLS/fdl_kl4/fdl2-dl.bin"

for f in "$SPD" "$FDL1" "$FDL2"; do
    [ -e "$f" ] || { echo "нет файла: $f" >&2; exit 1; }
done

[ "$(id -u)" -eq 0 ] || echo "внимание: BROM обычно требует root на USB; если не увидит телефон — запустите через sudo"

OUT="${OUT:-$PWD/dump_$(date +%Y%m%d_%H%M%S)}"
mkdir -p "$OUT"
LOG="$OUT/dump.log"

echo "==============================================="
echo " Дамп TECNO KM4 (только чтение)"
echo " Каталог: $OUT"
echo " Телефон: выключен, зажаты Volume+ и Volume−, USB подключён"
echo " Старт через 30 секунд, Ctrl+C для отмены"
echo "==============================================="
for i in $(seq 30 -1 1); do printf '\r  %2d ' "$i"; sleep 1; done; echo

# Единственная команда к устройству: exec FDL -> read_part. Ни записи, ни стирания.
"$SPD" --wait 600 --verbose 2 \
    exec_addr 0x65015f08 \
    fdl "$FDL1" 0x65000800 \
    fdl "$FDL2" 0x9efffe00 \
    exec \
    verbose 1 \
    path "$OUT" \
    read_part super 0 "$SUPER_BYTES" super.bin \
    read_part metadata 0 67108864 metadata.bin \
    reset >"$LOG" 2>&1
rc=$?

echo "spd_dump rc=$rc"
{
    echo "date: $(date -Is)"
    echo "rc: $rc"
    echo "super_bytes: $SUPER_BYTES"
} > "$OUT/result.txt"

fail=0
[ -f "$OUT/super.bin" ] || { echo "НЕТ super.bin" >&2; fail=1; }
if [ -f "$OUT/super.bin" ]; then
    size=$(stat -c%s "$OUT/super.bin")
    [ "$size" = "$SUPER_BYTES" ] && echo "super.bin размер ok: $size" || { echo "super.bin размер $size != $SUPER_BYTES" >&2; fail=1; }
fi
[ -f "$OUT/metadata.bin" ] || { echo "НЕТ metadata.bin" >&2; fail=1; }

if [ "$fail" -eq 0 ]; then
    ( cd "$OUT" && sha256sum super.bin metadata.bin > SHA256SUMS.txt )
    echo "--- SHA256SUMS ---"
    cat "$OUT/SHA256SUMS.txt"
    echo "--- проверка суперблока ---"
    lpdump "$OUT/super.bin" 2>/dev/null | head -8
    echo "ГОТОВО. Телефон должен загрузиться сам (reset)."
else
    echo "ЧАСТИЧНЫЙ ДАМП. Лог: $LOG" >&2
    tail -20 "$LOG" >&2
fi

exit "$fail"
