# Changelog

## v1.2 — не выпущено

Собрано по сессиям 2026-11-08…11-10. Релиз не делался: устройство
нестабильно, образ не снимался.

### Добавлено

- **Скрытие root** для Госуслуг и банков: Zygisk Assistant 2.1.4,
  PlayIntegrityFork v19, DenyList-цели, `pm hide com.topjohnwu.magisk`,
  ярлык Termux для запуска скрытого Magisk.
- **`lowram_multiwindow`**: снятие Android Go-ограничения
  (`ro.config.low_ram=false`) плюс `enable_freeform_support=1` —
  разделение экрана и плавающие окна.
- **`docs/known-issues.md`**: разбор ANR Firefox (magic mount, 4803
  записи в `mountinfo`), вылет Telegram из-за таймаута GMS, падения
  SystemUI при freeform, план по слабому железу.
- **`docs/fixes/play-store.md`**: обёртка `com.android.vending:background`
  (10-секундный таймаут старта) и почему её нельзя считать «хвостом».

### Не выпущено

- Готовый образ: `super` с этими изменениями не снимался.
- Google Prompt: диагностика без изменений, тема закрыта.
- AV1/YouTube: план есть, правок не было.

## v1.1 — 2026-11-08

Полный образ системы: `super.img`, снятый с рабочего телефона и проверенный
на нём. Прошивается одной командой `fastboot flash super super.img`, без
удаления logical-разделов и без сборки GSI на месте.

### Что внутри `super.img`

| Раздел | Источник |
|---|---|
| `system_a` | LineageOS 22.1 GSI, sha256 `cb4147e7…` (побайтово совпадает с GSI) |
| `system_ext_a` | сток TECNO, IMS на месте |
| `vendor_a`, `product_a`, `odm_a` | сток TECNO |
| `tr_*`, `*_dlkm` | сток TECNO |
| cow-разделов нет | чистая разметка |

Личных данных в образе нет: `userdata`, `persist`, NV и `metadata`
остаются на устройстве и стираются отдельно.

### Как собран

`super.bin` снят через BootROM (`scripts/dump-phone.sh`, только чтение),
проверен `lpdump`, `system_a` извлечён и сверен побайтово с исходным GSI.

## v1.0 — 2026-11-07

Первая публичная версия. Собрано из рабочего состояния телефона.

### База

- TECNO KM4 (Spark Go 2), UMS9230E, eMMC, 3 ГБ RAM.
- LineageOS 22.1 GSI (Android 15, `treble_arm64_bgN`, EXT4, GApps).
- Magisk v31.1, патченный `init_boot_a`.

### Модули

- `brightness_scale` v1 — шкала яркости 0–255 → 0–5119.
- `km4-stock-ims` 0.1 — VoLTE/IMS из стокового `system_ext`.
- `km4-usb-playback` 1.0 — USB-аудио.
- `km4_pocketmode` 1.1 — режим кармана.
- `bootanim_netrunner` 2.0 — заставка (276 МБ).
- `com.chiller3.bcr` 3.11 — запись звонков (внешний).

### Документация

- Установка GSI, разблокировка, root, откат.
- Причины и устройство каждого фикса.
- Скрипты проверки устройства и установки модулей.

### Известные ограничения

- VoWiFi, видеозвонки, FM-радио не проверялись.
- Откат ниже сборки `180010` не проверялся и не рекомендуется
  (`anti_rollback_status=1`).
- USB-микрофон не тестировался.
