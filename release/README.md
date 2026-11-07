# Релизы

В релиз кладётся собранное, в git — только исходники.

## Что в релизе

| Файл | Размер | Что |
|---|---|---|
| `super.img` | 9.52 ГиБ | весь `super`: LineageOS GSI + стоковые vendor/system_ext/product |
| `init_boot_patched.img` | 8 МиБ | Magisk v31.1 |
| `modules.tar.gz` | ~0.5 МиБ | все модули, готовые к установке |
| `SHA256SUMS` | — | контрольные суммы |

GitHub ограничивает файл релиза 2 ГиБ, поэтому архив режется на тома
`7z -v1900m`. Распаковка:

```bash
7z x CustomTecnoSparkGo2-vX.Y.7z.001
sha256sum -c SHA256SUMS
```

## Сборка релиза

1. Снять дамп с рабочего телефона: `sudo bash scripts/dump-phone.sh`
   (телефон выключен, Vol+ и Vol−, кабель).
2. Проверить дамп: `lpdump dump_*/super.bin`, размер 9 521 070 080 байт.
3. Собрать APK режима кармана:
   ```bash
   (cd modules/km4_pocketmode && bash build.sh)
   ```
4. Подготовить IMS:
   ```bash
   bash modules/km4-stock-ims/prepare.sh
   ```
5. Собрать архив модулей:
   ```bash
   bash scripts/pack-modules.sh
   ```
6. Упаковать и посчитать суммы:
   ```bash
   cp dump_*/super.bin release/super.img
   sha256sum super.img init_boot_patched.img modules.tar.gz > SHA256SUMS
   7z a -v1900m CustomTecnoSparkGo2-vX.Y.7z super.img init_boot_patched.img \
        modules.tar.gz SHA256SUMS
   ```
7. `gh release create vX.Y <тома> SHA256SUMS --notes-file CHANGELOG.md`

Заставка (`bootanimation.zip`, 276 МБ) лежит отдельно в релизе v1.0 —
в `super` она не входит, её ставит модуль `bootanim_netrunner`.

## Версионирование

`v<major>.<minor>` — major при смене GSI или базы, minor при добавлении
или правке модулей. Каждый релиз — запись в `CHANGELOG.md`.
