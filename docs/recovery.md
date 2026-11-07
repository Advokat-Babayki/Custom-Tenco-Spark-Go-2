# Бэкап и откат

## 1. Что обязательно сохранить до любых операций

| Что | Зачем |
|---|---|
| `super` (8.87 ГиБ) | всё: system, system_ext, vendor, product, odm |
| `metadata` (64 МиБ) | состояние Virtual A/B, без него `super` бесполезен |
| `init_boot_a`, `boot_a`, `vbmeta_a` | загрузка и AVB |
| NV-разделы (`l_fixnv*`, `l_deltanv*`, `prodnv`, `persist`, `calinv`, `transec`) | IMEI и калибровки; потеря необратима |

`userdata` в образ не входит и не должен: там личные данные.

## 2. Дамп через BootROM (spd_dump)

Телефон выключен, зажать нужную кнопку и подключить USB (вход в BROM).
Ничего не пишется — только чтение.

```bash
spd_dump --wait 300 exec_addr 0x65015f08 \
  fdl fdl1-dl.bin 0x65000800 \
  fdl fdl2-dl.bin 0x9efffe00 \
  exec path backup/ \
  read_part super 0 9521070080 super.bin \
  reset
```

Размер `super` — ровно `0x237800000` = 9 521 070 080 байт.

Проверенный дамп с этого устройства:

| Параметр | Значение |
|---|---|
| Размер | 9 521 070 080 байт |
| SHA-256 | `03093fc18569f262ceffce30aaf5b237113d86628e09c9b592ac87652b244504` |
| Проверка | `lpdump` читает суперблок, все logical на месте |

## 3. Откат

### Быстрый: вернуть свой `super`

```bash
adb reboot fastboot
fastboot flash super super.bin
fastboot reboot
```

`flush` занимает 5–15 минут, образ 8.87 ГиБ.

### Точечный: вернуть только system

```bash
fastboot delete-logical-partition system_a
fastboot flash system stock_system_a.img
```

Нужен стоковый `system_a`, которого нет в PAC — только в вашем дампе.

### Полный: заводской PAC

Скачать PAC своей сборки, прошить ResearchDownload (Windows) или
`spd_dump`. **Важно:** архив, который был под рукой при разблокировке —
`KM4-15.1.0.113SP02` — **старше** вашей `180010`. Это откат вниз при
`ro.boot.anti_rollback_status=1`. Не проверялось и не рекомендуется:
нужен PAC ровно вашей сборки или новее.

## 4. План Б при bootloop после GSI

Если система не стартует из-за dm-verity:

```bash
fastboot --disable-verity --disable-verification flash vbmeta vbmeta_a.img
```

`vbmeta_a.img` — ваш стоковый дамп. `boot`, `dtbo`, `trustos`, `modem`
не трогать ни при каких условиях: GSI рассчитан на стоковый vendor и ядро.

## 5. Что НЕ делать

- Не прошивать PAC от другой модели или другой ревизии платы.
- Не откатываться ниже `180010`.
- Не стирать `persist`, `prodnv`, NV-разделы «для чистоты» — IMEI не вернуть.
- Не включать `adb root` на постоянку.
- Не прошивать `boot` от другой сборки: ядро и init-ramdisk связаны с vendor.
