# VollaFlashDual

A **KernelSU / Magisk** module for the **Volla Quintus / zahedan (algiz, mt6877)**
that fixes both flashlight problems natively — no Xposed.

## What it fixes

### 1. Both flash LEDs light (all versions)
The stock MediaTek `libcameracustom.flashlight.so` hard-codes
`cust_isDualFlashSupport()`/`cust_isSubFlashSupport()` to `0`, so only one of the
two MT6360 LEDs fires. This module ships an 8-byte-patched copy returning `1`.

### 2. Torch brightness slider (v4.0)
Root-caused by reverse engineering: the current ROM's
`libmtkcam_hal_aidl_device.so` has `AidlCameraDevice::getTorchStrengthLevel()` and
`turnOnTorchWithStrengthLevel()` compiled as **stubs that return `-38` (ENOSYS)**.
Because the HAL reports "not implemented", Android hides the strength slider.

The device's original OS (**DariaOS**, which had a working slider) shipped the same
file with the **real** implementation — and its ABI is identical to the current
build:

- same `NEEDED` library list
- **zero** new imported symbols
- **156 == 156** exported symbols

So the DariaOS `libmtkcam_hal_aidl_device.so` drops in cleanly. Paired with the
DariaOS `libmtkcam_metastore.so` + `libmtkcam_metadata.so` (which report
`strengthMaximumLevel > 1`), the slider returns.

We deliberately **do not** swap the `camera.provider@2.6` HAL — that one has an
Android-15-vs-16 vtable mismatch that crash-loops `camerahalserver`. The AIDL
device layer is the correct, ABI-safe injection point.

## Install

1. KernelSU app → *Modules* → *Install from storage* → pick the ZIP.
2. Installer checks device = `algiz`, size-verifies the flashlight patch and the
   device lib, backs up all four stock files to
   `/data/local/tmp/vollaflashdual_backup/`.
3. Reboot.

After reboot: both LEDs light, and long-pressing the flashlight tile shows a
brightness slider.

## Auto-recovery (v4.0)

If the camera HAL ever crash-loops, the module **self-disables after 2 failed
boots** and restores stock — you can never get stuck with a broken camera. This
fixes the v3.x bug where the manual disable flag stuck permanently.

Manual recovery any time:
```
adb shell su -c 'touch /data/local/tmp/vollaflashdual_disable'
```
then reboot (the flag is honoured once and auto-cleared), or just remove the
module in KernelSU.

## Caveats

- Built against a specific ROM build; after a system OTA that updates these vendor
  libs, rebuild against the new files (the installer size-check guards against a
  mismatched flash).
- If the DariaOS device lib behaves differently on the A16 base, the slider may not
  appear but the camera keeps working (the functions fail gracefully, they don't
  abort). Auto-recovery covers the worst case regardless.
