# Мультиокно: split-screen и плавающие окна

## Симптом

В системе нет разделения экрана и плавающих окон: в недавних нет ни
«Разделить экран», ни «Мультиоконный режим».

```bash
cmd activity supports-multiwindow                    # false
cmd activity supports-split-screen-multi-window      # false
getprop ro.config.low_ram                            # true
```

## Причина

Прошивка — Android Go (`ro.config.low_ram=true`). Во фреймворке
`ActivityManager.isLowRamDeviceStatic()` возвращает `true`, и это
отключает **все** формы мультиокна, хотя сами флаги в ресурсах включены.

## Решение

### 1. Модуль `lowram_multiwindow`

На `post-fs-data` выставляет `ro.config.low_ram=false`:

```sh
RP=/debug_ramdisk/resetprop
[ -x "$RP" ] || RP=/product/bin/resetprop
"$RP" -n ro.config.low_ram false
```

Абсолютный путь к `resetprop` обязателен: на `post-fs-data` его нет
в `PATH`, и с голым `resetprop` модуль молча не срабатывает.

### 2. Настройки

```bash
adb shell settings put global enable_freeform_support 1
adb shell settings put global force_resizable_activities 0
```

- `enable_freeform_support=1` включает плавающие окна;
- `force_resizable_activities` **оставить 0**: при `low_ram` и
  принудительном ресайзе SystemUI падает с NPE (проверено, ловили
  краш интерфейса).

Обе настройки читаются при загрузке — нужен ребут.

## Проверка

```bash
adb shell getprop ro.config.low_ram                                  # false
adb shell cmd activity supports-multiwindow                          # true
adb shell cmd activity supports-split-screen-multi-window            # true
adb shell settings get global enable_freeform_support                # 1
```

В недавних: долгое нажатие на иконку → «Разделить экран» или
«Мультиоконный режим». Плавающее окно двигается и растягивается.

## Грабли

| Что | Результат |
|---|---|
| `enable_freeform_support=1` при `low_ram=true` | SystemUI падает |
| `force_resizable_activities=1` при `low_ram=true` | SystemUI падает |
| freeform без split | интерфейс нестабилен, окна не запускаются |
| `development_enable_freeform_windows_support` | не тот ключ, ничего не даёт |

## Откат

```bash
adb shell su -c 'touch /data/adb/modules/lowram_multiwindow/disable'
adb shell settings put global enable_freeform_support 0
adb reboot
```

## Чего ждать не стоит

Жеста «смахнуть приложение в бок и получить плавающее окно», как на
Samsung/Xiaomi, в AOSP нет — это фирменная оболочка. Нативно доступен
только путь через недавние.

## Ограничения

- Без Go-режима телефон потребляет больше памяти: 3 ГБ RAM — мало.
- PiP-видео этой сборкой не включается, это отдельная фича.
- На стоковом TECNO без root изменить `ro.config.low_ram` нельзя.
  Остаются только ADB-настройки, и только если multi-window не вырезан
  в ресурсах прошивки.
