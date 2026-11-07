# Релизы

В релиз кладётся собранное, в git — только исходники.

## Что в релизе

| Файл | Размер | Что |
|---|---|---|
| `system.img` | ~3.1 ГиБ | LineageOS 22.1 GSI (ext4, GApps) |
| `init_boot_patched.img` | 8 МиБ | Magisk v31.1 |
| `bootanimation.zip` | ~276 МиБ | заставка |
| `modules.tar.gz` | ~10 МиБ | все модули, готовые к установке |
| `SHA256SUMS` | — | контрольные суммы |

GitHub ограничивает файл релиза 2 ГиБ, поэтому `system.img` (и общий
архив) режется на тома `7z -v1900m`. Распаковка:

```bash
7z x CustomTecnoSparkGo2-vX.Y.7z.001
sha256sum -c SHA256SUMS
```

## Сборка релиза

1. Стоковая база и GSI — в `TECNO_KM4_RECON/` (в репозиторий не входят).
2. Собрать APK режима кармана:
   ```bash
   (cd modules/km4_pocketmode && bash build.sh)
   ```
3. Подготовить IMS:
   ```bash
   bash modules/km4-stock-ims/prepare.sh
   ```
4. Собрать архив модулей:
   ```bash
   bash scripts/pack-modules.sh
   ```
5. Упаковать и посчитать суммы:
   ```bash
   sha256sum system.img init_boot_patched.img bootanimation.zip modules.tar.gz > SHA256SUMS
   7z a -v1900m CustomTecnoSparkGo2-vX.Y.7z system.img init_boot_patched.img \
        bootanimation.zip modules.tar.gz SHA256SUMS
   ```
6. `gh release create vX.Y <тома> SHA256SUMS --notes-file CHANGELOG.md`

## Версионирование

`v<major>.<minor>` — major при смене GSI или базы, minor при добавлении
или правке модулей. Каждый релиз — запись в `CHANGELOG.md`.
