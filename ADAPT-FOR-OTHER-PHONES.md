# Adapting This Project For Other Phones

This repository is intentionally built for the Xiaomi Poco F1 / Pocophone F1 (`beryllium`).

The scripts are not universal flash tools. Android flashing is device-specific, and using the wrong recovery, ROM, boot image, firmware, or kernel can brick a phone.

## What Can Be Reused

The general structure can be reused:

- Check `adb` and `fastboot`.
- Detect the connected device.
- Verify the exact codename before flashing.
- Download only official ROM/recovery files.
- Verify checksums when available.
- Flash only the recovery or boot image required by the official guide.
- Use recovery sideload for the ROM.
- Log every major command.
- Ask for explicit confirmation before wiping or flashing.

## What Must Be Changed Per Device

For every new phone, update and re-check:

- Device codename.
- Official LineageOS device page.
- Official install guide.
- Official download/static build endpoint.
- Required firmware version.
- Required recovery image.
- Required partition commands.
- Whether the device uses A/B slots.
- Whether recovery is flashed, booted temporarily, or included in boot/vendor_boot/init_boot.
- GApps Android version and CPU architecture.
- Root method and boot image patching process.
- NetHunter kernel availability for the exact Android/ROM version.

## Non-Negotiable Safety Rules

- Never remove the device codename check.
- Never flash a file unless it is for the exact device codename.
- Never lock the bootloader after installing a custom ROM.
- Never bypass FRP, account locks, passwords, bootloader locks, or security protections.
- Never use EDL/test-point methods as part of this project.
- Never flash a NetHunter kernel built for a different Android or LineageOS version.

## Why This Matters

Two phones can both be Android 15 and still need completely different flashing commands.

For example, one device may use:

```text
fastboot flash recovery recovery.img
```

Another may need:

```text
fastboot flash vendor_boot vendor_boot.img
```

Another may require temporary booting:

```text
fastboot boot recovery.img
```

Using the wrong flow can make the phone fail to boot.

## Recommended Process For A New Device

1. Find the official LineageOS wiki page for the exact device.
2. Read the official install guide from start to finish.
3. Confirm the codename using Fastboot.
4. Copy this project into a new branch or folder.
5. Change only the device-specific constants first.
6. Add new safety checks before adding new flash commands.
7. Test the verification-only script before running any installer.
8. Keep a stock boot/recovery backup when possible.
9. Document every successful command in an install log.

If in doubt, stop before flashing.
