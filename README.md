# Poco F1 Fully Automated Android 15 Installer

This project helps automate installing official LineageOS on the Xiaomi Poco F1 / Pocophone F1, codename `beryllium`, from Windows PowerShell.

It is designed for a phone that currently has Kali NetHunter Pro / pure Kali Linux installed and is being replaced with official LineageOS.

## Read This First

- This removes Kali NetHunter Pro.
- This wipes all phone data.
- This is only for Xiaomi Poco F1 / Pocophone F1, codename `beryllium`.
- The phone must already be in Fastboot mode before running the main script.
- The script checks `fastboot getvar product` and stops unless the product is `beryllium`.
- The script will not lock the bootloader.
- Some recovery steps still require physical taps on the phone.
- Android Studio works normally after LineageOS boots and USB debugging is enabled.

Fastboot mode:

1. Power off the phone.
2. Hold **Volume Down + Power**.
3. Release when `FASTBOOT` appears.
4. Connect the USB cable to your Windows PC.

## Google Apps / Play Store

LineageOS does not include Google Play Store by default.

GApps are optional. If you want Play Store, provide an Android 15 `arm64` GApps zip and sideload it before the first boot:

```powershell
.\install-poco-f1-lineageos.ps1 -GappsZip "C:\path\gapps.zip"
```

If no GApps zip is provided, the phone boots clean LineageOS without Play Store.

## Requirements

- Windows PowerShell.
- Android Platform Tools installed.
- `adb.exe` and `fastboot.exe` available in `PATH`.
- Poco F1 in Fastboot mode.
- Battery preferably above 50%.
- A reliable USB cable.

Install Android Platform Tools:

1. Download from Google's official page: https://developer.android.com/tools/releases/platform-tools
2. Extract the zip, for example to `C:\platform-tools`.
3. Add that folder to your Windows `PATH`.
4. Open a new PowerShell window.
5. Test:

```powershell
adb version
fastboot --version
```

## Files

- `install-poco-f1-lineageos.ps1` - main guided installer.
- `verify-device.ps1` - safe device check only; does not modify the phone.
- `config.example.json` - example configuration.
- `SAFETY.md` - safety rules.
- `troubleshooting.md` - common fixes.
- `android-studio-after-install.md` - Android Studio setup after LineageOS boots.
- `logs\.gitkeep` - keeps the logs folder in the project.

## Recommended Run Order

1. Put Poco F1 in Fastboot mode.
2. Connect USB.
3. Open PowerShell in this project folder.
4. Run the safe checker:

```powershell
.\verify-device.ps1
```

5. Run the installer:

```powershell
.\install-poco-f1-lineageos.ps1
```

The installer can automatically download official LineageOS files for `beryllium`, or you can provide local files.

## Usage Examples

Automatic official download:

```powershell
.\install-poco-f1-lineageos.ps1
```

Use a config file:

```powershell
.\install-poco-f1-lineageos.ps1 -Config .\config.json
```

Use local LineageOS and recovery files:

```powershell
.\install-poco-f1-lineageos.ps1 -LineageZip "C:\path\lineage.zip" -RecoveryImg "C:\path\recovery.img"
```

Use local files and optional GApps:

```powershell
.\install-poco-f1-lineageos.ps1 -LineageZip "C:\path\lineage.zip" -RecoveryImg "C:\path\recovery.img" -GappsZip "C:\path\gapps.zip"
```

## What the Installer Does

1. Creates `logs` and `downloads` folders if needed.
2. Logs to `logs\install-yyyyMMdd-HHmmss.log`.
3. Checks `adb.exe` and `fastboot.exe`.
4. Checks that Fastboot detects the phone.
5. Checks `fastboot getvar product`.
6. Stops unless the product is `beryllium`.
7. Checks bootloader unlock status if available.
8. Shows a wipe/flashing warning.
9. Requires this exact confirmation:

```text
INSTALL LINEAGEOS ON BERYLLIUM
```

10. Downloads official LineageOS and matching recovery, unless local paths are provided.
11. Verifies downloads are non-empty and checks SHA-256 when official checksum files are available.
12. Flashes Lineage Recovery:

```powershell
fastboot flash recovery recovery.img
```

13. Tries to reboot to recovery.
14. Guides you through factory reset in Lineage Recovery.
15. Guides you to `Apply update > Apply from ADB`.
16. Sideloads LineageOS.
17. Optionally sideloads GApps if provided.
18. Reboots or asks you to choose `Reboot system now`.

The PC may show `adb sideload` stopping around 47%. That can be normal; trust the final result shown by recovery and the script exit status.

## Official Sources Used

- Device page: https://wiki.lineageos.org/devices/beryllium/
- Install guide: https://wiki.lineageos.org/devices/beryllium/install/
- Downloads page: https://download.lineageos.org/devices/beryllium
- Static build list: https://download-static.lineageos.org/beryllium

