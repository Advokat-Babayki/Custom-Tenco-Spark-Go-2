# Устройство

Данные сняты с живого телефона через `adb shell getprop`, `lpdump`, `dumpsys`,
`lsblk`. Дата: 2026-11-01.

## Идентификация

| Параметр | Значение |
|---|---|
| Маркетинговое имя | TECNO SPARK Go 2 |
| Модель | TECNO KM4 |
| Product / Device | KM4-RU / TECNO-KM4 |
| Hardware | `ums9230_KM4_go` |
| SoC | Unisoc UMS9230E (Tiger T7250/T615), 2×A75 + 6×A55, Mali-G57 |
| RAM | 3 ГБ (`ro.config.low_ram=true`, Android Go Edition) |
| Накопитель | eMMC 64 ГБ, `/data` ≈ 48 ГиБ |
| Экран | 720×1600, плотность 280 |
| Android (сток) | 15, SDK 35 |
| Сборка | `KM4-15.1.2.180SP05(RU001PL001AZ)`, incremental `180010` |
| Патч безопасности | 2026-07-01 |
| Vendor fingerprint | Android 13 (`TP1A`) — типичная для Transsion схема «новый system на старом vendor» |
| SELinux | Enforcing |
| Шифрование | FBE + metadata encryption |

## Разметка

Virtual A/B, но **слот `_b` логических разделов отсутствует** — обновления
идут через snapshots, а не через второй набор разделов.

| Раздел | Размер | Комментарий |
|---|---|---|
| `super` (p46) | 8.87 ГиБ | logical: system, system_ext, vendor, product, odm, tr_* |
| `system_a` (сток) | 0.85 ГиБ | заменяется GSI |
| `system_ext_a` | 1.51 ГиБ | стоковый, не трогается — отсюда файлы IMS |
| `vendor_a` | 1.59 ГиБ | стоковый |
| `product_a` | 1.50 ГиБ | стоковый |
| `boot_a` / `init_boot_a` | 64 / 8 МиБ | `init_boot_a` патчится Magisk |
| `userdata` (p79) | ≈47.6 ГиБ | стирается при разблокировке и `fastboot -w` |

Полная таблица: `TECNO_KM4_RECON/PARTITIONS.md` (в исходных материалах,
не в репозитории).

## Что чем занято после установки

| Раздел | Содержимое |
|---|---|
| `system_a` | LineageOS 22.1 GSI, 3.06 ГиБ |
| `system_ext_a`, `vendor_a`, `product_a`, `odm_a` | сток TECNO, не изменялись |
| `init_boot_a` | Magisk v31.1 |
| `boot_a`, `dtbo_a`, `vbmeta_a` | сток, не изменялись |
| `/data` | Magisk, модули, данные пользователя |

`veritymode=enforcing`, `verifiedbootstate=orange`, `flash.locked=0` — так
выглядит нормально разблокированное устройство с AVB в режиме enforcing.
