# Релизы

В релиз кладётся собранное, в git — только исходники.

## Что в релизе

| Файл | Размер | Что |
|---|---|---|
| `super.img` | 9.52 ГиБ | весь `super`: LineageOS GSI + стоковые vendor/system_ext/product |
| `init_boot_patched.img` | 8 МиБ | Magisk v31.1 |
| `modules.tar.gz` | ~0.5 МиБ | все модули, готовые к установке |
| `SHA256SUMS` | — | контрольные суммы |

GitHub ограничивает файл релиза 2 ГиБ, а соединение рвётся, поэтому архив
режется на куски по 500 МиБ. Скачивание и сборка:

```bash
sha256sum -c SHA256SUMS.parts
cat CustomTecnoSparkGo2-v1.1.tar.zst.part* | zstd -d | tar -x
```

Заливка с повторами (обрыв куска не рушит остальное):

```bash
bash scripts/upload-release.sh v1.1
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
   tar -cf - super.img init_boot_patched.img modules.tar.gz | zstd -T2 -3 -o CustomTecnoSparkGo2-vX.Y.tar.zst
   split -b 500M -d -a 2 CustomTecnoSparkGo2-vX.Y.tar.zst CustomTecnoSparkGo2-vX.Y.tar.zst.part
   sha256sum CustomTecnoSparkGo2-vX.Y.tar.zst.part* > SHA256SUMS.parts
   ```
7. `gh release create vX.Y --notes-file CHANGELOG.md` + `bash scripts/upload-release.sh vX.Y`

Заставка (`bootanimation.zip`, 276 МБ) лежит отдельно в релизе v1.0 —
в `super` она не входит, её ставит модуль `bootanim_netrunner`.

## Версионирование

`v<major>.<minor>` — major при смене GSI или базы, minor при добавлении
или правке модулей. Каждый релиз — запись в `CHANGELOG.md`.
