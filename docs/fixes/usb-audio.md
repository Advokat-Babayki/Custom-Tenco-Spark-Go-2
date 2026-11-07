# USB-аудио

## Симптом

При подключении USB-ЦАП или USB-наушников звук остаётся в динамике
телефона, маршрут на USB не переключается.

## Причина

В GSI-аудиополитике нет профилей PCM для USB-устройств, а стоковый
vendor HAL их не объявляет. Поток уходит на speaker по умолчанию.

## Решение — `km4-usb-playback`

Модуль подкладывает два стоковых конфига с добавленными USB-профилями:

| Файл | Что изменено |
|---|---|
| `system/vendor/etc/primary_audio_policy_configuration.xml` | добавлены `usb_device`/`usb_headset` profiles |
| `system/vendor/etc/audio_platform_config.xml` | включён USB playback path |

Файлы в репозитории — это диффы от стоковых: меняются только профили,
остальное совпадает с vendor.

## Проверка

1. Подключить USB-ЦАП.
2. Воспроизвести трек.
3. Проверить маршрут:
   ```bash
   adb shell dumpsys audio | grep -i -A3 'Devices:'
   ```

Ожидается `usb_device` в активных устройствах вывода.

## Откат

```bash
adb shell su -c 'rm -rf /data/adb/modules/km4-usb-playback'
adb reboot
```

## Ограничения

- Проверено только на воспроизведении; USB-микрофон не тестировался.
- Задержка и частоты зависят от конкретного ЦАП.
- Модуль не трогает `vendor` на диске — только overlayfs.
