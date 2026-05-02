# Android Studio After Install

After LineageOS boots:

1. Complete Android setup.
2. Open **Settings > About phone**.
3. Tap **Build number** 7 times.
4. Open **Settings > System > Developer options**.
5. Enable **USB debugging**.
6. Connect the USB cable.
7. Select **File Transfer** if prompted.
8. Accept the RSA fingerprint popup on the phone.
9. On Windows, run:

```powershell
adb kill-server
adb start-server
adb devices
```

10. If the device shows `unauthorized`, unlock the phone and accept the RSA popup.
11. Open Android Studio.
12. Select the Poco F1 from the device dropdown.
13. Press **Run**.
14. Android Studio installs the APK directly to the phone.

