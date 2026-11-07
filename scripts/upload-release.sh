#!/usr/bin/env bash
# Заливка релиза: черновик -> части по одной с повторами -> публикация.
# Обрыв части не удаляет релиз и не рушит остальные.
set -uo pipefail

R="${1:?укажи тег, например v1.1}"
DIR="$(cd "$(dirname "$0")/.." && pwd)/release"
cd "$DIR"

# черновик создаётся один раз; если уже есть — не мешаем
if ! gh release view "$R" >/dev/null 2>&1; then
    echo "[$(date +%H:%M:%S)] создаю черновик $R"
    gh release create "$R" --draft --title "$R" --notes-file "$DIR/../CHANGELOG.md" || {
        echo "не удалось создать черновик" >&2; exit 1; }
fi

# уже залитые части пропускаем: имя + размер
declare -A HAVE=()
while IFS=$'\t' read -r n s; do HAVE["$n"]="$s"; done < <(
    gh release view "$R" --json assets --jq '.assets[] | "\(.name)\t\(.size)"' 2>/dev/null
)

upload() {
    local f="$1" sz n=0
    sz=$(stat -c%s "$f")
    if [ "${HAVE[$f]:-}" = "$sz" ]; then
        echo "[$(date +%H:%M:%S)] $f уже залит, пропуск"
        return 0
    fi
    while [ "$n" -lt 8 ]; do
        n=$((n+1))
        echo "[$(date +%H:%M:%S)] $f попытка $n"
        if gh release upload "$R" "$f" --clobber 2>&1 | tail -1; then
            echo "[$(date +%H:%M:%S)] $f ok"
            return 0
        fi
        sleep 10
    done
    echo "[$(date +%H:%M:%S)] $f FAILED" >&2
    return 1
}

fail=0
for f in CustomTecnoSparkGo2-*.tar.zst.part*; do
    upload "$f" || fail=1
done
upload SHA256SUMS.parts || fail=1
upload SHA256SUMS || fail=1

if [ "$fail" -eq 0 ]; then
    gh release edit "$R" --draft=false --latest
    echo "[$(date +%H:%M:%S)] опубликовано: $R"
else
    echo "[$(date +%H:%M:%S)] есть ошибки, релиз остался черновиком — перезапусти скрипт" >&2
fi

exit "$fail"
