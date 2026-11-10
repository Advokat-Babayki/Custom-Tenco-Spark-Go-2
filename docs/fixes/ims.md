# IMS / VoLTE / звонки

## Симптом

На GSI нет VoLTE: звонки падают в 2G/3G, в LTE звонок не проходит;
SMS в LTE не уходят; после ребута IMS не поднимается.

## Причина

IME-стек Transsion/Unisoc живёт в стоковом `system_ext` и `vendor`
(`com.spreadtrum.ims`, `ims_bridged`, `libimsbrd.so`). GSI приносит
свой `system_ext` без них. Vendor остаётся стоковым, поэтому половина
стека на месте, а половины нет.

## Решение — `km4-stock-ims`

Модуль возвращает стоковые файлы через overlayfs и поднимает стек:

| Что | Откуда |
|---|---|
| `system_ext/priv-app/ims/ims.apk` | стоковый `system_ext_a` |
| `system_ext/lib64/libimsbrd.so`, `libn3am_jni.so` | оттуда же |
| `system_ext/bin/ims_bridged` | оттуда же |
| `system_ext/etc/permissions/com.spreadtrum.ims.xml` | оттуда же |
| `system_ext/etc/init/ims_bridged.rc` | оттуда же |

В репозитории бинарников нет — их достаёт `modules/km4-stock-ims/prepare.sh`
из стокового образа `system_ext_a` (см. README модуля).

Дальше:

```sh
# post-fs-data.sh
resetprop -n persist.vendor.sys.volte.enable true
resetprop -n persist.vendor.sys.single.imsstack true
resetprop -n persist.ims.apn ims

# service.sh
pm enable com.spreadtrum.ims
cmd overlay enable me.phh.treble.overlay.sprdims_telephony
nohup /system/system_ext/bin/ims_bridged &
magiskpolicy --live "..."
```

`sepolicy.rule` даёт только те разрешения, которых не хватает
`priv_app`/`rild`/`system_server`. SELinux остаётся **Enforcing**;
`permissive` и `setenforce 0` не используются.

## Проверка

```bash
adb shell getprop | grep -i -E 'volte|ims'
adb shell dumpsys telephony.registry | grep -i ims
adb shell 'logcat -d | grep -i -E "ims|volte" | tail -50'
```

Практически: позвонить и принять вызов, проверить, что значок VoLTE
не пропадает и звук идёт в обе стороны.

## Что не сработало

Был вариант `km4-unisoc-ims-trial` (0.2) — пробовал поднять Unisoc IMS
без стоковых APK. Не дал устойчивого результата, оставлен отключённым
в исходных материалах и в репозиторий не входит.

## Откат

```bash
adb shell su -c 'rm -rf /data/adb/modules/km4-stock-ims'
adb reboot
```

## Ограничения

- VoWiFi не проверялся.
- Видеозвонки оператора не проверялись.
- После обновления GSI модуль нужно проверить заново: пути к файлам
  в `system_ext` могут измениться.
- Пофайловый overlay из 3239 файлов раздувает `mountinfo` и даёт ANR
  Firefox. См. [../known-issues.md](../known-issues.md).
