# VollaFlashDual

A **KernelSU / Magisk** module that makes **both** flash LEDs light on the
**Volla Quintus (algiz, MediaTek mt6877)** — natively, by fixing the camera
HAL itself. No Xposed, no daemon, no polling.

## Root cause

The Quintus has a dual-LED flash driven by an MT6360, exposed as two kernel
channels (`mt6360_flash_ch1`, `mt6360_flash_ch2`), both `max_brightness 31`.
Both work at the kernel level.

Disassembling `/vendor/lib64/libcameracustom.flashlight.so` shows MediaTek
disabled the second LED in the HAL:

```
cust_isDualFlashSupport:  mov w0, wzr   ; return 0
                          ret
cust_isSubFlashSupport:   mov w0, wzr   ; return 0
                          ret
```

Because dual-flash support reports `0`, the HAL only ever drives `ch1`.

## The fix

This module ships a binary-patched copy of that library where those two
functions return `1`:

```
cust_isDualFlashSupport:  mov w0, #1
                          ret
cust_isSubFlashSupport:   mov w0, #1
                          ret
```

**Exactly 8 bytes** differ from stock. Everything else is byte-identical. The
patched library is overlaid onto `/vendor/lib64/` via KernelSU magic mount, so
the real partition is never modified. The camera HAL then drives **both** flash
channels natively, for camera flash and the system torch alike.

- Stock lib SHA-256: `b2b136403c048a764ad2c7858ae10342db45f561808bf7f4b5de4bb9793698c5`
- Patched lib SHA-256: `afa81368cfedd89e8d8ba3f477855905699dc565a5ba6cac9b0b2ca1d55d60ac`

## Install

1. Download the module ZIP from [Releases](../../releases) or
   [Actions artifacts](../../actions).
2. KernelSU app → *Modules* → *Install from storage* → pick the ZIP.
3. Reboot.

The installer verifies your device is `algiz` and that the stock library size
matches the one the patch was built against; it **aborts** if they differ (a
different ROM build would ship a different library and flashing it could break
the camera). It also backs up your stock library to
`/data/local/tmp/vollaflashdual_backup/` before doing anything.

## Safety / recovery

- Uninstalling the module in KernelSU restores stock behaviour on reboot.
- If the camera ever misbehaves and you can't reach the UI, disable via ADB:
  ```
  adb shell su -c 'touch /data/local/tmp/vollaflashdual_disable'
  ```
  then reboot — the module self-disables and stock is restored.
- Your bootloader is unlocked, so worst case you can also just remove the module
  from `/data/adb/modules/` in recovery/safe mode.

## Scope

- This module fixes the **dual-LED** behaviour only.
- The **torch brightness slider** (HAL reports `torchStrengthMaxLevel = 1`) is a
  separate item, handled by the companion project **VollaFlashFix**.

## Important

This library is specific to one ROM build (fingerprint
`volla/algiz/...:16/BP4A.251205.006/...`). After a system OTA that updates the
camera HAL, **uninstall and rebuild** the patch against the new library, or the
size check will (correctly) refuse to flash.
