# Режим кармана (Pocket Mode)

## Симптом

Телефон в кармане сам просыпается от датчика приближения: касания сквозь
ткань открывают приложения, звонки сбрасываются, включается фонарик.

## Почему GSI не помогает

`config_proximityCheckOnWake=false` в GSI, а отдельного Pocket Mode
в LineageOS нет. Штатный AOSP-механизм не активируется, потому что
флаг выключен на уровне фреймворка.

## Решение — `km4_pocketmode`

Привилегированное приложение `dev.km4.pocketmode` в `/system/priv-app`,
сервис слушает `TYPE_PROXIMITY`:

- срабатывает только когда **экран включён** и **keyguard заблокирован**
  (то есть телефон в кармане, а не в руке с разблокированным экраном);
- показывает поверх keyguard полноэкранное предупреждение, которое
  перехватывает касания;
- после выхода — пауза 5 минут, чтобы не доставать повторно.

Аварийный выход: **одновременно зажать Volume+ и Volume−** (~1 секунда).
Экран разблокируется, показывается тост «пауза», режим молчит 5 минут.

## Состав

| Файл | Что |
|---|---|
| `app/src/dev/km4/pocketmode/*.java` | сервис, activity-предупреждение, boot-receiver |
| `module/system/priv-app/Km4PocketMode/Km4PocketMode.apk` | собранный APK |
| `module/system/etc/permissions/privapp-permissions-km4-pocketmode.xml` | `START_ACTIVITIES_FROM_BACKGROUND` |
| `service.sh` | `appops set SYSTEM_ALERT_WINDOW allow`, `deviceidle whitelist`, старт сервиса |
| `build.sh` | сборка APK (aapt2 + javac + d8 + apksigner) |

## Разрешения

| Разрешение | Почему |
|---|---|
| `START_ACTIVITIES_FROM_BACKGROUND` | `signature\|privileged`, выдаётся privapp-XML |
| `SYSTEM_ALERT_WINDOW` | запасной путь, основной — activity |
| `RECEIVE_BOOT_COMPLETED` | автозапуск |

`DEVICE_POWER` не выдаётся даже priv-app (`signature\|role`), поэтому
экран не гасится принудительно — вместо этого блокируются касания.

## Сборка

```bash
cd modules/km4_pocketmode
ANDROID_BUILD_TOOLS=<sdk>/build-tools/<ver> \
ANDROID_JAR=<sdk>/platforms/android-35/android.jar \
bash build.sh
```

Скрипт создаёт `build/Km4PocketMode.apk` и подписывает локальным ключом
(`keystore.jks`, в репозиторий не входит — генерируется при первой сборке).

## Проверка

```bash
adb shell su -c 'log -t Km4PocketMode'
adb shell dumpsys sensorservice | grep -i prox
# закрыть верхнюю часть экрана рукой при заблокированном экране
```

## Откат

```bash
adb shell su -c 'rm -rf /data/adb/modules/km4_pocketmode'
adb reboot
```

## Ограничения

- Датчик — `prox_stk3335-x`, порог берётся из `getMaximumRange()`.
- На заблокированном экране предупреждение перекрывает часы и уведомления —
  это ожидаемо.
- Если экран уже разблокирован, режим не срабатывает (осознанно).
