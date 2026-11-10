# Скрытие root от банков и Госуслуг

## Симптом

`ru.rostel` (Госуслуги) при запуске показывает «приложение не может
работать на устройстве с root или модифицированной ОС» и закрывается.
Аналогично ведут себя банковские приложения.

## Что проверяет Госуслуги

Разбор APK (jadx 1.5.6):

| Проверка | Где |
|---|---|
| пакет `com.topjohnwu.magisk` | `f01.a`, списки пакетов/путей |
| файлы `su`, `busybox`, `magisk` | `RootCheckNative`, `libtoolChecker.so` |
| `ro.debuggable`, `ro.secure`, `Build.TAGS` | `RootProviderImpl` |
| rw-монтирования, наличие Xposed, эмулятор | `ru.minsvyaz.safety.*` |

Порядок: сначала ROOT, и только если он не сработал — проверка USB
(«отключите устройство от компьютера»). То есть при подключённом кабеле
приложение всё равно покажет USB-блок — это не root.

## Решение

### 1. Zygisk Assistant

`snake-4/Zygisk-Assistant` v2.1.4 — скрывает `su`, `busybox`, `magisk`,
магисковские монтирования и сокеты от выбранных процессов, подменяет
пропсы (`ro.debuggable=0`, `ro.build.type=user`, `ro.build.tags=release-keys`,
`ro.boot.verifiedbootstate=green`, `ro.boot.flash.locked=1`).

```bash
su -c "magisk --install-module /data/local/tmp/za.zip"
```

### 2. Выключить Enforce DenyList

Zygisk Assistant сам использует DenyList как список целей, поэтому
принудительный режим должен быть выключен:

```bash
su -c "magisk --sqlite \"update settings set value=0 where key='denylist';\""
# zygisk=1, denylist=0
```

### 3. Заполнить DenyList

```bash
su -c "magisk --denylist add com.idamob.tinkoff.android"
su -c "magisk --denylist add com.idamob.tinkoff.android:SelfSupport"
su -c "magisk --denylist add com.idamob.tinkoff.android:pushservice"
su -c "magisk --denylist add ru.sberbankmobile"
su -c "magisk --denylist add ru.sberbankmobile:bms_caller_id"
su -c "magisk --denylist add ru.sberbankmobile:pushservice"
su -c "magisk --denylist add ru.sberbankmobile:isolated"
su -c "magisk --denylist add ru.vtb24.mobilebanking.android"
su -c "magisk --denylist add ru.vtb24.mobilebanking.android:fp"
su -c "magisk --denylist add ru.vtb24.mobilebanking.android:phoenix"
su -c "magisk --denylist add ru.vtb24.mobilebanking.android:pushservice"
su -c "magisk --denylist add ru.gosuslugi.goskey"
su -c "magisk --denylist add ru.rostel"
su -c "magisk --denylist add ru.rostel:phoenix"
```

Список смотреть: `magisk --denylist ls`.

### 4. PlayIntegrityFork

`PlayIntegrityFork` v19 — подмена отпечатка для Play Integrity. На
root-блок Госуслуг не влияет, нужен для банков и Play.

```bash
su -c "magisk --install-module /data/local/tmp/pif.zip"
```

### 5. Спрятать пакет Magisk

Решающий шаг: Госуслуги проверяют наличие пакета `com.topjohnwu.magisk`
напрямую.

```bash
su -c "pm hide com.topjohnwu.magisk"
```

Проверка:

```bash
adb shell dumpsys package com.topjohnwu.magisk | grep -m1 hidden=
# hidden=true
```

`pm hide` скрывает приложение от всех, включая запуск из лончера.
Любые обращения к `com.topjohnwu.magisk.provider` падают с
«Could not find provider» — это нормально, демон Magisk, `su` и модули
работают независимо.

## Открыть Magisk, когда он скрыт

Ярлык Termux (`~/.shortcuts/Magisk`): разскрывает пакет, открывает
Magisk, ждёт уход фокуса и снова прячет. Скрипт лежит в
`scripts/termux-magisk-shortcut.sh`, установка:

```bash
adb push scripts/termux-magisk-shortcut.sh /data/local/tmp/Magisk
adb shell 'su -c "mkdir -p /data/data/com.termux/files/home/.shortcuts && cp /data/local/tmp/Magisk /data/data/com.termux/files/home/.shortcuts/Magisk && chown -R 10280:10280 /data/data/com.termux/files/home/.shortcuts && chmod 700 /data/data/com.termux/files/home/.shortcuts /data/data/com.termux/files/home/.shortcuts/Magisk"'
```

Дальше — виджет Termux:Widget на рабочем столе. После «Home» пакет
снова скрывается.

## Откат

```bash
su -c "pm unhide com.topjohnwu.magisk"
su -c "touch /data/adb/modules/zygisk-assistant/disable"
su -c "touch /data/adb/modules/playintegrityfix/disable"
su -c "magisk --sqlite \"update settings set value=1 where key='denylist';\""
adb reboot
```

## Если снова перестало работать

Искать в таком порядке: обновился пакет Госуслуг и добавил новую
проверку → обновить DenyList; Magisk перестал быть скрытым после
переустановки → повторить `pm hide`; Play Integrity перестал проходить →
обновить PIF.

## Ограничения

- Проверки банков меняются с обновлениями; список пакетов придётся
  поддерживать.
- VPN и подключённый USB тоже дают блок у Госуслуг — это не root.
- Play Integrity verdicts не проверялись отдельно.
- `pm hide` ломает автоматику, которая ходит к Magisk через провайдер.
