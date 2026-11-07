#!/usr/bin/env bash
# Заливает части релиза по одной с повторами. Обрыв одного куска не рушит всё.
set -uo pipefail

R="${1:?укажи тег, например v1.1}"
DIR="$(cd "$(dirname "$0")/.." && pwd)/release"
cd "$DIR"

upload() {
    local f="$1" n=0
    while [ "$n" -lt 6 ]; do
        n=$((n+1))
        echo "[$(date +%H:%M:%S)] $f попытка $n"
        if gh release upload "$R" "$f" --clobber 2>&1 | tail -1; then
            echo "[$(date +%H:%M:%S)] $f ok"
            return 0
        fi
        sleep 5
    done
    echo "[$(date +%H:%M:%S)] $f FAILED" >&2
    return 1
}

fail=0
for f in CustomTecnoSparkGo2-v1.1.tar.zst.part*; do
    upload "$f" || fail=1
done

# суммы перезаливаем в конце, чтобы они соответствовали последней нарезке
upload SHA256SUMS.parts || fail=1
upload SHA256SUMS || fail=1

echo "[$(date +%H:%M:%S)] готово, fail=$fail"
exit "$fail"
