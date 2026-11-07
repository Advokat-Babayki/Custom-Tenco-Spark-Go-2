# Разблокировка, root, модули

## 1. Разблокировка загрузчика

На KM4 работает **официальный путь TECNO**, без эксплойтов и без патча
загрузчика.

1. Включить VPN с не-российским выходом. Сервер TECNO из РФ отвечает
   `Server Error`, и `OEM unlocking` не завершается.
2. Настройки → О телефоне → 7 раз по «Номер сборки» (режим разработчика).
3. Для разработчиков → **OEM unlocking** → включить, дождаться ответа сервера.
4. Включить «Отладка по USB», подключить телефон к ноутбуку.
5. Перезагрузиться в загрузчик:
   ```bash
   adb reboot bootloader
   fastboot devices
   ```
6. Разблокировать (телефон спросит подтверждение на экране):
   ```bash
   fastboot flashing unlock
   ```
7. Устройство сотрёт `userdata` и загрузится в сток.

Проверка:

```bash
adb shell getprop ro.boot.verifiedbootstate   # orange
adb shell getprop ro.boot.flash.locked         # 0
adb shell getprop ro.boot.vbmeta.device_state  # unlocked
adb shell getprop sys.oem_unlock_allowed       # 1
```

Если `OEM unlocking` в меню нет или пункт серый — не пытаться обойти
эксплойтами (CVE-2022-38694 на KM4 + eMMC не доведён до рабочего
состояния, а риск кирпича высокий). VPN и повтор — правильное решение.

## 2. Magisk

Патчится **`init_boot`**, не `boot`. На этом устройстве init-ramdisk
лежит в отдельном 8-МиБ разделе.

Через приложение Magisk:

1. Установить Magisk v31.1 (файл `Magisk-v31.1.apk`).
2. Раздел «Установить» → «Выбрать и пропатчить файл» → `init_boot_a.img`
   из стокового образа (`init_boot.img` из PAC).
3. Полученный файл — на ноутбук.
4. `adb reboot fastboot` → `fastboot flash init_boot magisk_patched-*.img`.
5. `fastboot reboot`.

Проверка: `adb shell su -c id` → `uid=0(root)`.

Модули лежат в `/data/adb/modules`. Файловая система `/system` при этом
не меняется — модули маунтятся поверх через overlayfs.

## 3. Модули

```bash
bash scripts/install-modules.sh              # все
bash scripts/install-modules.sh brightness_scale   # один
```

Скрипт копирует каталоги в `/data/adb/modules/<id>`, ставит права
`0755` и просит перезагрузку.

После перезагрузки:

```bash
adb shell su -c 'ls /data/adb/modules'
adb shell su -c 'log -t KM4 magisk modules ok'
```

Удаление модуля — удалить каталог и перезагрузить. Модуль с файлом `disable`
внутри каталога не загружается.

## 4. Безопасность

- SELinux остаётся Enforcing. Все фиксы — точечные `sepolicy.rule`,
  без `permissive`.
- Root доступен только приложениям, которым вы разрешили в Magisk.
- `adb root` на GSI userdebug может работать; по умолчанию его лучше не
  включать.

## 5. Если что-то пошло не так

| Симптом | Что делать |
|---|---|
| Bootloop на логотипе | `fastboot --disable-verity --disable-verification flash vbmeta vbmeta_a.img` (стоковый, с флагами) |
| Не грузится после удаления модуля | зайти в Magisk через `adb shell su`, проверить `/data/adb/modules` |
| Нет `su` | перепатчить `init_boot` и прошить заново |
| Забыли, что меняли | `fastboot getvar all`, сверить с [device.md](device.md) |
