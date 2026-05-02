# Safety Rules

This project performs a real operating system installation on your phone. Read this before running anything.

## Critical Warnings

- This wipes all data.
- This is only for Xiaomi Poco F1 / Pocophone F1, codename `beryllium`.
- Never lock the bootloader.
- Never run `fastboot oem lock`.
- Never run `fastboot flashing lock`.
- Never use Mi Flash `clean all and lock`.
- Never flash another device's files.
- Use official LineageOS files.
- Keep battery above 50%.
- Use a good USB cable.
- If something fails, stay calm and keep the phone in Fastboot or Recovery.
- Do not use EDL or test-point methods.
- Do not bypass locks, accounts, passwords, FRP, Mi account protections, or other security protections.

## What This Project Refuses To Do

The scripts do not contain bootloader locking commands.

The scripts stop if `fastboot getvar product` does not report `beryllium`.

The scripts do not flash bootloader, modem, firmware, or partition files outside the intended Lineage Recovery and LineageOS sideload process.

The scripts do not bypass security protections.

## Before Running

Make sure:

- You understand that data will be erased.
- Your Poco F1 is charged.
- You have a reliable USB cable.
- `adb.exe` and `fastboot.exe` are installed.
- The phone is in Fastboot mode.
- You have read the official LineageOS install page:
  https://wiki.lineageos.org/devices/beryllium/install/

