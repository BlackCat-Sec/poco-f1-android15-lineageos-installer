# Kali NetHunter Notes

This project installed Kali NetHunter tooling on top of LineageOS 22.2 / Android 15 with Magisk root.

## Current Working Setup

The current safe setup is:

```text
Android 15 / LineageOS 22.2
Magisk root
Termux
Kali NetHunter root environment
NetHunter KeX
```

Useful commands inside Termux:

```bash
nethunter
nethunter -r
nethunter kex start
```

The KeX password used during this setup was:

```text
kalikali
```

## Official Kernel Status

The official NetHunter kernel list currently shows Poco F1 support for:

```text
beryllium-los
Android 14 / LineageOS 21
kernel 4.9
HID, BT_RFCOMM, Injection
```

It does not currently list an official Poco F1 Android 15 / LineageOS 22.x NetHunter kernel.

## Do Not Flash The Android 14 Kernel On Android 15

The Android 14 / LineageOS 21 NetHunter kernel should not be flashed on Android 15 / LineageOS 22.2.

Possible failure modes:

- Bootloop
- Broken Wi-Fi
- Broken Bluetooth
- Broken touch/display behavior
- Broken Magisk/root
- Recovery-only boot

## Future Android 14 Path

If full NetHunter kernel features become more important than Android 15, the safer path is:

1. Back up anything important.
2. Downgrade to a matching LineageOS 21 / Android 14 build for `beryllium`.
3. Install matching Android 14 GApps if wanted.
4. Re-root with Magisk.
5. Install the matching official `beryllium-los` NetHunter package/kernel.

Do not mix Android 15 userspace with an Android 14 NetHunter kernel.
