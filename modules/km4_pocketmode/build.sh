#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD="$ROOT/build"
BT="${ANDROID_BUILD_TOOLS:-$ROOT/sdk/android-15}"
AJ="${ANDROID_JAR:-$ROOT/sdk/android-35/android.jar}"

if [ ! -x "$BT/aapt2" ] || [ ! -f "$AJ" ]; then
    echo "android build-tools/android.jar not found" >&2
    echo "set ANDROID_BUILD_TOOLS and ANDROID_JAR" >&2
    exit 1
fi

export LD_LIBRARY_PATH="$BT/lib64:$BT/lib:${LD_LIBRARY_PATH:-}"

rm -rf "$BUILD"
mkdir -p "$BUILD/classes" "$BUILD/dex" "$BUILD/gen"

"$BT/aapt2" compile --dir "$ROOT/app/res" -o "$BUILD/res.zip"
"$BT/aapt2" link \
    -o "$BUILD/app-unsigned.apk" \
    -I "$AJ" \
    --manifest "$ROOT/app/AndroidManifest.xml" \
    --min-sdk-version 30 \
    --target-sdk-version 35 \
    --java "$BUILD/gen" \
    "$BUILD/res.zip"

mapfile -d '' SOURCES < <(find "$ROOT/app/src" "$BUILD/gen" -name '*.java' -print0)
javac --release 11 -classpath "$AJ" -d "$BUILD/classes" "${SOURCES[@]}"

mapfile -d '' CLASSES < <(find "$BUILD/classes" -name '*.class' -print0)
bash "$BT/d8" --lib "$AJ" --min-api 30 --output "$BUILD/dex" "${CLASSES[@]}"

python3 - "$BUILD/app-unsigned.apk" "$BUILD/dex/classes.dex" <<'PY'
import sys, zipfile
apk, dex = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(apk, "a", zipfile.ZIP_DEFLATED) as z:
    z.write(dex, "classes.dex")
PY

"$BT/zipalign" -f 4 "$BUILD/app-unsigned.apk" "$BUILD/app-aligned.apk"

if [ ! -f "$ROOT/keystore.jks" ]; then
    keytool -genkeypair -keystore "$ROOT/keystore.jks" \
        -storepass pocketmode -keypass pocketmode \
        -alias pocketmode -keyalg RSA -keysize 2048 -validity 10000 \
        -dname "CN=KM4 Pocket Mode" >/dev/null
fi

bash "$BT/apksigner" sign \
    --ks "$ROOT/keystore.jks" \
    --ks-pass pass:pocketmode \
    --key-pass pass:pocketmode \
    --out "$BUILD/Km4PocketMode.apk" \
    "$BUILD/app-aligned.apk"

bash "$BT/apksigner" verify --print-certs "$BUILD/Km4PocketMode.apk" >/dev/null

MODULE_APK="$ROOT/module/system/priv-app/Km4PocketMode/Km4PocketMode.apk"
mkdir -p "$(dirname "$MODULE_APK")"
cp "$BUILD/Km4PocketMode.apk" "$MODULE_APK"

echo "built: $BUILD/Km4PocketMode.apk"
echo "module: $MODULE_APK"
