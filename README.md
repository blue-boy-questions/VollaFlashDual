# VollaFlashDual

A tiny **KernelSU / Magisk** module that makes **both** flash LEDs light on the
**Volla Quintus (algiz, MediaTek mt6877)** — no Xposed required.

## Why

The Quintus has a dual-LED flash driven by an MT6360, exposed as two independent
kernel channels:

```
/sys/class/leds/mt6360_flash_ch1/brightness   (max_brightness 31)
/sys/class/leds/mt6360_flash_ch2/brightness   (max_brightness 31)
```

Both work at the kernel level, but MediaTek's camera HAL hard-codes
`cust_isDualFlashSupport()` to `0` (confirmed by disassembling
`libcameracustom.flashlight.so`), so only **ch1** ever lights during camera
flash and torch.

## How it works

A small root daemon (`service.sh`, started by KernelSU as a late_start service)
polls `ch1` every 40 ms and mirrors its brightness onto `ch2`. Whenever anything
turns the flash on — camera, the system torch tile, FlashDim — the second LED
follows automatically.

Because it runs as root in the correct SELinux context, it works under SELinux
**enforcing** and needs no app, no Xposed, and no framework hooks.

## Install

1. Download the module ZIP from [Releases](../../releases) or the
   [Actions artifacts](../../actions).
2. Flash it in the KernelSU app (or Magisk) → *Modules* → *Install from storage*.
3. Reboot.

Verify it's running:

```
adb shell su -c 'cat /data/local/tmp/vollaflashdual.log'
```

## Scope / limits

- This module only fixes the **dual-LED** behaviour (both LEDs on).
- **Torch brightness / strength slider** is a separate problem (the HAL reports
  `torchStrengthMaxLevel = 1`) and is handled by the companion project
  **VollaFlashFix** (Xposed) or a future binary-patch approach.
- Brightness range is the kernel's `max_brightness` (31). The daemon only
  mirrors whatever value the system already wrote to ch1 — it never exceeds it,
  so it can't overdrive the flash.

## Uninstall

Remove the module in KernelSU/Magisk and reboot. Nothing else is modified;
`ch2` simply stops being mirrored.
