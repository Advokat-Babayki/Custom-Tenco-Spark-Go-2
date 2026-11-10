# Play Store: обновления не начинаются

## Симптом

Кнопка «Обновить» нажимается, но загрузка не стартует. Новые приложения
не ставятся. Интерфейс при этом живой.

## Причина

Play Store запускает фоновый процесс `com.android.vending:background`.
Система даёт на старт процесса 10 секунд. На перегруженном телефоне
процесс не успевает — его убивает таймаут, и обновление не начинается.

## Решение

`/data/adb/post-fs-data.d/10-vending-wrap.sh`:

```sh
#!/system/bin/sh
RP=/debug_ramdisk/resetprop
[ -x "$RP" ] || RP=/product/bin/resetprop
"$RP" -n wrap.com.android.vending:background logwrapper
```

При каждой загрузке даёт фоновому процессу запас времени через
`logwrapper`.

Проверка:

```bash
adb shell getprop wrap.com.android.vending:background   # logwrapper
adb shell 'ps -A | grep vending'                        # com.android.vending:background жив
```

## Грабли

- `wrap.*` для GMS добавлять не нужно — только для
  `com.android.vending:background`.
- Скрипт легко принять за «хвост» при уборке костылей. Он рабочий:
  удалишь — Play Store снова перестанет обновлять.
- После обновления GSI/Play Store проверить заново: имя процесса может
  измениться.

## Откат

```bash
adb shell su -c 'rm /data/adb/post-fs-data.d/10-vending-wrap.sh'
adb reboot
```
