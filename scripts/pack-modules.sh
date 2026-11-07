#!/usr/bin/env bash
# Собирает modules.tar.gz для релиза: только готовые к установке каталоги.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/release/modules.tar.gz}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

for dir in "$ROOT"/modules/*/; do
    name="$(basename "$dir")"

    # у pocketmode модуль в подкаталоге module/, а app/ и build.sh в архив не нужны
    if [ -f "$dir/module/module.prop" ]; then
        cp -r "$dir/module" "$TMP/$name"
    elif [ -f "$dir/module.prop" ]; then
        cp -r "$dir" "$TMP/$name"
    else
        continue
    fi
done

if [ ! -f "$TMP/km4-stock-ims/system/system_ext/priv-app/ims/ims.apk" ]; then
    echo "предупреждение: km4-stock-ims без стоковых файлов (prepare.sh не запускался)" >&2
fi

mkdir -p "$(dirname "$OUT")"
tar -czf "$OUT" -C "$TMP" .
echo "готово: $OUT ($(du -h "$OUT" | cut -f1))"
