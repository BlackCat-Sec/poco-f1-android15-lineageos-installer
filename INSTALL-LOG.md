# Install Log: Poco F1 Android 15 + NetHunter Root

This document records the successful installation flow used on a Xiaomi Poco F1 / Pocophone F1 (`beryllium`) that previously had Kali NetHunter Pro / pure Kali Linux installed.

It is written so another user can understand the order of operations. Do not blindly copy commands for a different phone.

## Final State

- Device: Xiaomi Poco F1 / Pocophone F1
- Codename: `beryllium`
- OS installed: LineageOS 22.2 / Android 15
- Root: Magisk
- Google Apps: installed with MindTheGapps
- NetHunter: Kali NetHunter root/rootless-style environment inside Termux
- KeX password used during setup: `kalikali`

## Files Used

Official LineageOS files:

- `lineage-22.2-20260428-nightly-beryllium-signed.zip`
- `recovery-20260428-beryllium.img`

Google Apps:

- MindTheGapps Android 15 `arm64`

Root:

- Magisk APK
- Boot image extracted from the matching LineageOS zip
- Magisk-patched boot image generated from that boot image

NetHunter apps:

- NetHunter Store
- Termux
- NetHunter KeX
- Hacker's Keyboard

## High-Level Steps

1. Put the phone in Fastboot mode.
2. Verify `fastboot getvar product` reports `beryllium`.
3. Flash Lineage Recovery.
4. Boot to Lineage Recovery.
5. Factory reset / format data from recovery.
6. Choose `Apply update > Apply from ADB`.
7. Sideload the LineageOS zip.
8. Before first boot, choose `Apply from ADB` again and sideload GApps if Play Store is wanted.
9. Reboot to Android.
10. Complete setup and enable USB debugging.
11. Patch the matching LineageOS boot image with Magisk.
12. Flash the Magisk-patched boot image only after confirming the device still boots.
13. Install NetHunter Store, Termux, NetHunter KeX, and Hacker's Keyboard.
14. Run the official NetHunter rootless installer from Termux.
15. Verify root and NetHunter.

## Verification Results

Android:

```text
ro.product.device = beryllium
ro.lineage.version = 22.2-20260428-NIGHTLY-beryllium
ro.build.version.release = 15
```

Magisk root:

```text
uid=0(root) gid=0(root) groups=0(root) context=u:r:magisk:s0
```

NetHunter root:

```text
uid=0(root) gid=0(root) groups=0(root)
whoami = root
Kali GNU/Linux Rolling 2026.1
```

Kali package update:

```text
Fetched 72.3 MB
878 packages can be upgraded
```

## Important NetHunter Kernel Note

The official NetHunter kernel list currently has Poco F1 support for `beryllium-los` on Android 14 / LineageOS 21, not Android 15 / LineageOS 22.2.

For this Android 15 install, do not flash the Android 14 NetHunter kernel. It can cause bootloops or broken hardware.

Safe options:

- Stay on Android 15 with Magisk + NetHunter root environment.
- Wait for an official Android 15 / LineageOS 22.x `beryllium-los` NetHunter kernel.
- Downgrade to Android 14 / LineageOS 21 later if full NetHunter kernel features are required.
