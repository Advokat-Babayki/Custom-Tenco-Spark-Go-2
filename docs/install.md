# Установка

Есть два пути: из готового образа (релиз) и с нуля (сток → GSI → root → модули).
Оба требуют **разблокированного загрузчика** — см. [root.md](root.md).

> **Опасно:** всё, что ниже, стирает `userdata`. Сделайте бэкап
> (`adb pull /sdcard/...`), пока телефон ещё работает.

## Требования

- TECNO KM4 / Spark Go 2, `ums9230_KM4_go`, eMMC.
- Сборка не ниже `180010` (проверить `ro.build.display.id`).
- Linux с `adb` и `fastboot` ≥ 35 (`fastbootd` обязателен).
- Разблокированный загрузчик.
- Заряд > 60 %.

Проверка:

```bash
bash scripts/check-device.sh
```

## Путь A — готовый образ из релиза

1. Скачать архив и `SHA256SUMS` из Releases.
2. Сверить: `sha256sum -c SHA256SUMS`.
3. Распаковать: `7z x <архив>.7z.001`.
4. Войти в fastbootd:
   ```bash
   adb reboot fastboot
   fastboot getvar is-userspace      # должно быть: yes
   fastboot getvar current-slot      # a
   ```
5. Прошить (файлы из распакованной папки):
   ```bash
   fastboot flash system system.img
   fastboot flash init_boot init_boot_patched.img
   fastboot -w
   fastboot erase metadata
   fastboot reboot
   ```
6. Первый запуск 5–15 минут. Если bootloop — см. [recovery.md](recovery.md),
   план Б с `vbmeta`.
7. Установить модули: `bash scripts/install-modules.sh`.

## Путь B — с нуля (то, как это делалось)

### 1. Разблокировка

См. [root.md](root.md), раздел 1. После неё данные стёрты, `verifiedbootstate=orange`.

### 2. Установка GSI

```bash
adb reboot fastboot
fastboot getvar is-userspace          # yes
fastboot getvar current-slot          # a

# в super нет свободного места, а cow-разделы пустые — их можно удалить
fastboot delete-logical-partition system_a-cow
fastboot delete-logical-partition system_ext_a-cow
fastboot delete-logical-partition vendor_a-cow

fastboot flash system LineageOS-22.1-20250319-GAPPS-EXT4-GSI.img   # ~148 c
fastboot -w
fastboot erase metadata
fastboot reboot
```

Образ, который проверен на этом устройстве:

| Параметр | Значение |
|---|---|
| Файл | `LineageOS-22.1-20250319-GAPPS-EXT4-GSI.img` |
| Размер | 3 287 248 896 байт |
| SHA-256 | `cb4147e7d756fd8edd197360b37ec60799f72b7705aef3e633a655db29391a6e` |
| Сборка | `treble_arm64_bgN`, Android 15, EXT4, A/B, GApps |

`fastboot -w` может ругнуться на `cache` (`Erasing failed`) — это нормально,
раздел физический и не используется. На загрузку не влияет.

### 3. Root

Патченный `init_boot` из релиза либо свой:

```bash
# на телефоне: Magisk → Установить → «Выбрать и пропатчить файл»
# взять init_boot_a.img из стока, скопировать результат обратно
adb pull /sdcard/Download/magisk_patched-*.img
adb reboot fastboot
fastboot flash init_boot magisk_patched-*.img
fastboot reboot
```

Проверка: `adb shell su -c id` → `uid=0`.

### 4. Модули

```bash
bash scripts/install-modules.sh
```

Скрипт кладёт модули из `modules/` в `/data/adb/modules` и просит перезагрузку.

## После установки: что проверить

| Что | Как |
|---|---|
| Загрузка | `adb shell getprop sys.boot_completed` → `1` |
| Экран | `adb shell wm size` → 720×1600 |
| Сенсор | `adb shell dumpsys input \| grep TOUCH` |
| Камеры | `adb shell dumpsys media.camera \| grep 'Number of camera'` → 2 |
| SIM/LTE | `adb shell getprop gsm.sim.state` |
| Звонки | позвонить и принять вызов |
| Яркость | подвигать ползунок от минимума до максимума |
| Root | `adb shell su -c id` |

## Чего этот образ не делает

- Не меняет `vendor`, `boot`, `dtbo`, `modem`, `trustos` — GSI живёт на стоковом vendor.
- Не отключает SELinux.
- Не фиксит то, что не проверялось: VoWiFi, 5G (его нет), FM-радио,
  видеовыход, точные калибровки камер.
