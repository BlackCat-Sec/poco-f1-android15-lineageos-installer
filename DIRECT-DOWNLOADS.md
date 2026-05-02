# Direct Downloads

This repository does not commit ROM zips, recovery images, APKs, Magisk-patched boot images, or Google Apps packages.

That is intentional.

## Why The Required Files Are Not In Git

- LineageOS builds are large and change weekly.
- Android ROM zips are too large for normal git hosting.
- Recovery and boot images must match the exact build.
- Google Apps packages are optional and come from a separate project.
- Magisk-patched boot images are device/build-specific and should never be reused blindly.
- Users should get security-sensitive installation files from their official source.

## One-Command Official Download

Use this project script to download the latest official Poco F1 / `beryllium` LineageOS zip and matching recovery image:

```powershell
.\download-required-files.ps1
```

To also download and extract Google's official Android Platform Tools:

```powershell
.\download-required-files.ps1 -DownloadPlatformTools
```

The script downloads from:

- LineageOS static build list: https://download-static.lineageos.org/beryllium
- LineageOS mirrorbits payload URLs linked by that official page
- Google Platform Tools: https://dl.google.com/android/repository/platform-tools-latest-windows.zip

It verifies official LineageOS SHA-256 checksums when downloading the ROM and recovery.

## Optional Files

Google Apps are optional. LineageOS does not include Play Store by default.

If Play Store is wanted, use an Android 15 `arm64` GApps zip and sideload it before first boot. This project does not vendor a GApps zip.

Magisk is optional. If root is wanted, patch the boot image extracted from the exact LineageOS build installed on the phone. Do not reuse someone else's patched boot image.

## What GitHub Users Should Download

For the normal Poco F1 Android 15 install:

1. Clone or download this repository.
2. Run:

```powershell
.\download-required-files.ps1 -DownloadPlatformTools
```

3. Put the phone in Fastboot mode.
4. Run:

```powershell
.\verify-device.ps1
.\install-poco-f1-lineageos.ps1
```

The installer can also download the official LineageOS files automatically, so the downloader is mainly for users who want to prepare files before connecting the phone.
