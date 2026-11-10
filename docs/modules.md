# Модули

Модули ставятся в `/data/adb/modules`, `/system` не меняется.
Состояние на 2026-11-10, GSI + Magisk v31.1.

| Модуль | Версия | Что делает |
|---|---|---|
| `brightness_scale` | v1 | яркость 0–255 → 0–5119 |
| `km4-stock-ims` | 0.1 | VoLTE/IMS из стока |
| `km4-usb-playback` | 1.0 | USB-аудио |
| `com.chiller3.bcr` | 3.11 | запись звонков (внешний) |
| `km4_pocketmode` | 1.1 | режим кармана |
| `bootanim_netrunner` | 2.0 | заставка |
| `lowram_multiwindow` | 1.0 | split-screen и freeform |
| `zygisk-assistant` | 2.1.4 | скрытие root (внешний) |
| `playintegrityfix` | v19 | Play Integrity (внешний) |

Внешние модули в репозитории не лежат: ставятся из релизов авторов.

- Zygisk Assistant: <https://github.com/snake-4/Zygisk-Assistant>
- PlayIntegrityFork: <https://github.com/osm0sis/PlayIntegrityFork>
- BCR: <https://github.com/chenxiaolong/BCR>

## Установка

```bash
bash scripts/install-modules.sh                    # все локальные
bash scripts/install-modules.sh lowram_multiwindow  # один
```

Внешние:

```bash
adb push za.zip /data/local/tmp/
adb shell 'su -c "magisk --install-module /data/local/tmp/za.zip"'
```

## Порядок загрузки

`post-fs-data.sh` — до старта Android, `service.sh` — после
`sys.boot_completed`. В `post-fs-data` нет `PATH` от Magisk, поэтому
бинарники вызываются по абсолютному пути:

```sh
RP=/debug_ramdisk/resetprop
[ -x "$RP" ] || RP=/product/bin/resetprop
```

Голый `resetprop` там молча не работает — на этом уже попадались.

## Удаление

```bash
adb shell su -c 'rm -rf /data/adb/modules/<id>'
adb reboot
```

Файл `disable` внутри каталога отключает модуль без удаления.

## Скрытие root

`zygisk-assistant` + `playintegrityfix` + `pm hide com.topjohnwu.magisk`
описаны в [fixes/root-hiding.md](fixes/root-hiding.md).

## Побочный эффект: mount-буря

Пофайловый overlay от `km4-stock-ims` (3239 файлов) и BCR раздувает
`mountinfo` до ~4800 записей. Из-за этого Firefox получает ANR на старте.
См. [known-issues.md](known-issues.md).
