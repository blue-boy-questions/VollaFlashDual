# VollaFlashDual

**KernelSU / Magisk** module for the **Volla Quintus (algiz, MediaTek mt6877)**
that fixes the flashlight — both problems, natively, no Xposed.

## What it fixes

1. **Both flash LEDs light.** The stock MediaTek HAL
   (`libcameracustom.flashlight.so`) hard-codes `cust_isDualFlashSupport()` and
   `cust_isSubFlashSupport()` to `0`, so only one of the two MT6360 LEDs ever
   fires. This module ships an 8-byte-patched copy where they return `1`.

2. **Torch brightness slider (v3.0).** The stock camera provider HAL reports
   `strengthMaximumLevel = 1`, so Android hides the strength slider. The sister
   device **DariaOS (zahedan / Bound)** — same mt6877, same camera provider
   `@2.6` — ships a newer build of
   `android.hardware.camera.provider@2.6-impl-mediatek.so` that actually
   implements torch strength (`getTorchStrengthLevel`,
   `turnOnTorchWithStrengthLevel`, `setTorchLevel`). This module overlays that
   DariaOS HAL onto the Volla ROM.

Both files are magic-mounted over `/vendor/lib64/` — the real partition is never
modified.

## Why the HAL swap is safe (ABI check)

The DariaOS provider needs exactly **two** imported symbols beyond the stock
Volla provider:

- `NSMetadataProviderManager::valueForByDeviceId(int)` — exported by the
  device's own `libmtkcam_metastore.so`
- `IMetadata::IEntry::itemAt(uint, Type2Type<int>)` — exported by the device's
  own `libmtkcam_metadata.so`

Both are already present on the Volla ROM, and the `NEEDED` library list is
otherwise identical, so the swap resolves cleanly with no extra files.

## Install

1. KernelSU app → *Modules* → *Install from storage* → pick the ZIP.
2. The installer verifies device = `algiz`, size-checks the flashlight patch,
   and backs up both stock libraries to `/data/local/tmp/vollaflashdual_backup/`.
3. Reboot.

After reboot: both LEDs light for camera/torch, and long-pressing the flashlight
tile should show a brightness slider.

## Recovery

The HAL swap is the higher-risk part (cross-ROM library). If the camera
misbehaves:

```
adb shell su -c 'touch /data/local/tmp/vollaflashdual_disable'
```

then reboot — the module self-disables and stock libraries are restored. Or
remove the module in KernelSU. Your bootloader is unlocked, so you can also
delete it from `/data/adb/modules/` in safe mode.

## Caveats

- Built against a specific Volla ROM
  (`volla/algiz/...:16/BP4A.251205.006/...`) and a specific DariaOS build. After
  a system OTA that updates the camera HAL, rebuild against the new libraries.
- If the torch strength metadata isn't present on your build, the HAL falls back
  to default behaviour (logs `STRENGTH_DEFAULT_LEVEL not found`) — the slider may
  not appear, but the camera keeps working.

## Credits

Dual-LED patch + HAL analysis: reverse-engineered from
`libcameracustom.flashlight.so`. Torch-strength HAL sourced from the DariaOS
(zahedan) vendor image for the same SoC.
