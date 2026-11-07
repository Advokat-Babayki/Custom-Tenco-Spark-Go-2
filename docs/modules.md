# Модули

Модули ставятся в `/data/adb/modules`, `/system` не меняется.
Все проверены на LineageOS 22.1 GSI + Magisk v31.1.

| Модуль | Версия | Статус | Что делает |
|---|---|---|---|
| `brightness_scale` | v1 | работает | пересчёт яркости 0–255 → 0–5119 |
| `km4-stock-ims` | 0.1 | работает | VoLTE/IMS из стока |
| `km4-usb-playback` | 1.0 | работает | USB-аудио |
| `com.chiller3.bcr` | 3.11 | работает | запись звонков (внешний) |
| `km4_pocketmode` | 1.1 | работает | режим кармана |
| `bootanim_netrunner` | 2.0 | работает | заставка (276 МБ) |

## Установка

```bash
bash scripts/install-modules.sh                    # все
bash scripts/install-modules.sh km4_pocketmode     # один
```

или вручную:

```bash
adb push modules/brightness_scale /data/local/tmp/
adb shell su -c 'cp -r /data/local/tmp/brightness_scale /data/adb/modules/'
adb reboot
```

## Удаление

```bash
adb shell su -c 'rm -rf /data/adb/modules/<id>'
adb reboot
```

Если модуль не даёт загрузиться — создать внутри каталога пустой файл
`disable` через recovery или `adb` в ранней загрузке. Magisk пропустит модуль.

## Внешний модуль BCR

`com.chiller3.bcr` — не наш код, GPL-3.0:
<https://github.com/chenxiaolong/BCR>. Ставится из релиза проекта;
в репозитории его нет, чтобы не тащить чужую сборку.

После установки:

```bash
adb shell su -c 'pm grant com.chiller3.bcr android.permission.READ_CALL_LOG'
# в приложении BCR выбрать папку для записей
```

Записи складываются в выбранную папку на `/sdcard`, звонки пишутся
с обеих сторон.

## Порядок загрузки

`post-fs-data.sh` выполняется до старта Android (props, монтирования),
`service.sh` — после `sys.boot_completed`. Скрипты падают молча, поэтому
после установки смотреть `logcat` и `log -t` сообщения модуля.

## Требования

- Magisk v31.1+, `/data` не шифруется заново.
- SELinux Enforcing — не отключать. Все правила точечные в `sepolicy.rule`.
- После обновления Magisk модули не слетают, но `sepolicy.rule`
  применяется при старте `magiskd`.
