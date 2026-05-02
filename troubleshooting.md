# Troubleshooting

## fastboot not recognized

Install Android Platform Tools from Google's official page:

https://developer.android.com/tools/releases/platform-tools

Extract it, add the folder containing `fastboot.exe` to `PATH`, then open a new PowerShell window.

## adb not recognized

Install Android Platform Tools and add the folder containing `adb.exe` to `PATH`.

Test:

```powershell
adb version
```

## fastboot devices empty

- Confirm the phone shows `FASTBOOT`.
- Try a different USB port.
- Try a different USB cable.
- Install or reinstall Android USB drivers.
- Avoid USB hubs.
- Run PowerShell as Administrator if Windows driver permissions are acting oddly.

## waiting for any device

This usually means Windows does not see the phone correctly.

- Reconnect USB.
- Use another USB port.
- Reinstall drivers.
- Check Device Manager.
- Confirm the phone is in Fastboot mode, not Recovery or Android.

## product is not beryllium

Stop immediately. This project is only for Poco F1 / Pocophone F1, codename `beryllium`.

Do not flash anything.

## recovery flashing failed

- Confirm bootloader is unlocked.
- Confirm `fastboot getvar product` says `beryllium`.
- Try another USB cable.
- Try another USB port.
- Re-run `.\verify-device.ps1`.
- Read the exact error in `logs`.

Do not lock the bootloader.

## phone did not boot to recovery

If `fastboot reboot recovery` does not work:

1. Keep the phone connected.
2. Hold **Volume Up + Power**.
3. Release when Lineage Recovery appears.

If it boots somewhere else, power off and use **Volume Up + Power** again.

## adb devices does not show sideload

In Lineage Recovery:

1. Choose **Apply update**.
2. Choose **Apply from ADB**.
3. Then run:

```powershell
adb devices
```

The device should show `sideload`.

## sideload stuck at 47%

This is common. The PC progress can stop around 47% even when the phone completes the install.

Check the phone screen and the final PowerShell result.

## sideload failed

- Confirm the zip is for `beryllium`.
- Confirm the zip is official LineageOS.
- Re-download the file.
- Check SHA-256 if available.
- Repeat **Apply update > Apply from ADB** and sideload again.

## bootloop

- First boot can take several minutes.
- If it keeps rebooting, go back to recovery.
- Run factory reset again.
- Sideload LineageOS again.
- If GApps were installed, make sure the GApps zip is Android 15 and `arm64`.

## Play Store missing

LineageOS does not include Play Store by default.

To get Play Store, you must sideload a compatible Android 15 `arm64` GApps package before the first boot.

## GApps bootloop

- Make sure the package is Android 15.
- Make sure it is `arm64`.
- Use a smaller GApps package if available.
- Factory reset, sideload LineageOS again, then sideload the correct GApps before first boot.

## Android Studio not detecting phone

After LineageOS boots:

- Enable Developer options.
- Enable USB debugging.
- Accept the RSA fingerprint popup.
- Run:

```powershell
adb kill-server
adb start-server
adb devices
```

## ADB unauthorized

Unlock the phone and accept the RSA fingerprint popup.

If it does not appear:

```powershell
adb kill-server
adb start-server
adb devices
```

Then reconnect USB.

## Windows driver issue

Open Device Manager and look for the phone under Android, USB, or Unknown devices.

Install or update Android USB drivers, then reconnect the phone.

## bad USB cable

Some cables only charge and do not transfer data. Use a known good data cable.

## phone reboots back to recovery

- Factory reset from recovery.
- Sideload LineageOS again.
- Reboot system.
- If GApps were used, verify they match Android 15 `arm64`.

## Restart Safely From Fastboot

To reboot from Fastboot:

```powershell
fastboot reboot
```

To try recovery from Fastboot:

```powershell
fastboot reboot recovery
```

If that does not work, use **Volume Up + Power** manually.

## Restart Safely From Recovery

In Lineage Recovery, choose **Reboot system now**.

If you need to return to Fastboot, choose the recovery reboot options if available, or power off and hold **Volume Down + Power**.

