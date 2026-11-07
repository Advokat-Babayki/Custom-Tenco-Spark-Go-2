# Яркость

## Симптом

Ползунок яркости работает в диапазоне 5 % мощности панели: на максимуме
тускло, на минимуме экран чёрный. Автояркость ведёт себя так же.

## Причина

Узел подсветки: `/sys/class/backlight/sprd_backlight/brightness`,
`max_brightness = 5119`. Vendor Lights HAL пишет туда значение
Android-слайдера 0–255 без пересчёта. Итог: 255/5119 = 5 % мощности.

Проверка:

```bash
adb shell su -c 'cat /sys/class/backlight/sprd_backlight/max_brightness'   # 5119
adb shell settings get system screen_brightness                             # 0..255
adb shell su -c 'cat /sys/class/backlight/sprd_backlight/brightness'
```

## Решение

Модуль `brightness_scale`:

- `service.sh` запускает `inotifyd` на узле подсветки;
- на каждую запись HAL `handler.sh` читает `screen_brightness` (0–255),
  считает `a * 5119 / 255` и пишет обратно;
- `0` не переписывается — экран погашен;
- нижняя граница 300, чтобы слайдер не уводил панель в ноль;
- событийный вариант выбран вместо опроса: опрос каждые 0.2 с дрался
  с HAL и давал резкие скачки.

`sepolicy.rule`:

```
allow magisk sysfs_transsion_backlight_midtest file { write open read getattr }
```

## Проверка

| Слайдер | Узел |
|---|---|
| 255 | 5119 |
| 128 | 2569 |
| 60 | 1204 |
| 3 | 300 |

```bash
adb shell settings put system screen_brightness 128
adb shell su -c 'cat /sys/class/backlight/sprd_backlight/brightness'   # 2569
```

## Откат

```bash
adb shell su -c 'rm -rf /data/adb/modules/brightness_scale'
adb reboot
```

## Ограничения

- Яркость не калибруется по датчику освещённости — автояркость остаётся
  такой, какой её отдаёт GSI.
- При выключенном экране значение 0 не трогается, поэтому «просыпание»
  идёт с последней запомненной яркостью.
