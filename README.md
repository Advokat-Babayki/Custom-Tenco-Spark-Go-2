# Custom Tecno Spark Go 2 — LineageOS 22.1 + Magisk

Кастомная сборка для **TECNO Spark Go 2 (модель KM4, Unisoc UMS9230E)**:
LineageOS 22.1 GSI (Android 15), root через Magisk и набор модулей, которые
чинят то, что GSI на этом железе ломает.

> Custom Android 15 build for TECNO Spark Go 2 (KM4): LineageOS 22.1 GSI + Magisk
> + systemless fixes for brightness, IMS/VoLTE, USB audio, call recording and
> pocket mode.

## Что внутри

| Компонент | Версия |
|---|---|
| Прошивка-база | `KM4-15.1.2.180SP05(RU001PL001AZ)`, incremental `180010` |
| System | LineageOS 22.1 GSI, `treble_arm64_bgN`, EXT4, с GApps |
| Root | Magisk v31.1, патченный `init_boot_a` |
| Загрузчик | официальная разблокировка TECNO (OEM unlocking + `fastboot flashing unlock`) |

Модули:

| Модуль | Что чинит |
|---|---|
| `brightness_scale` | шкала яркости 0–255 вместо панельных 0–5119 |
| `km4-stock-ims` | VoLTE/IMS: звонки и SMS в LTE |
| `km4-usb-playback` | воспроизведение звука на USB-ЦАП/наушники |
| `com.chiller3.bcr` | запись всех звонков (внешний модуль) |
| `km4_pocketmode` | режим кармана: блокировка касаний датчиком приближения |
| `bootanim_netrunner` | кастомная заставка Cyberpunk |

## Быстрый старт

1. Прочитать [docs/install.md](docs/install.md) целиком — там требования,
   порядок шагов и откат.
2. Проверить, что у вас та же ревизия и сборка:
   ```bash
   adb shell getprop ro.product.model          # TECNO KM4
   adb shell getprop ro.build.display.id       # ...180SP05...
   adb shell getprop ro.boot.hardware          # ums9230_KM4_go
   ```
3. Разблокировать загрузчик: [docs/root.md](docs/root.md) (раздел 1).
4. Прошить образ из [Releases](../../releases).
5. Установить модули: `scripts/install-modules.sh`.

Скрипт проверки устройства перед прошивкой:

```bash
bash scripts/check-device.sh
```

## Документация

| Файл | О чём |
|---|---|
| [docs/device.md](docs/device.md) | характеристики, разметка, версии |
| [docs/install.md](docs/install.md) | установка GSI с нуля и из готового образа |
| [docs/root.md](docs/root.md) | разблокировка, Magisk, модули |
| [docs/recovery.md](docs/recovery.md) | бэкапы и откат к стоку |
| [docs/modules.md](docs/modules.md) | все модули и как их ставить |
| [docs/boot-animation.md](docs/boot-animation.md) | кастомная заставка |
| [docs/fixes/](docs/fixes) | почему каждый фикс нужен и как он работает |

## Совместимость

Только **TECNO KM4 / Spark Go 2**, `ro.boot.hardware=ums9230_KM4_go`,
eMMC, 3 ГБ RAM, прошивка не ниже `180010`.

Другие модели TECNO (Spark Go 1, Spark 20 и т.п.) — **не прошивать**.
Даже похожий Unisoc UMS9230 не гарантирует совпадения разметки и Trusty.

Откат ниже `180010` рискован: `ro.boot.anti_rollback_status=1`. Не проверялось
экспериментально и не рекомендуется.

## Лицензия и чужие файлы

Код модулей и документация — как есть, без гарантий. Стоковые блобы TECNO
(IMS APK, библиотеки, загрузочные образы) остаются собственностью TECNO;
в репозитории их нет, кроме случаев, где это необходимо для работы модуля.
Сборка образа требует собственного стокового ROM.
