#!/system/bin/sh
# VollaFlashDual v4.0 - install-time script (KernelSU / Magisk)
#
# ROOT CAUSE (reverse-engineered):
#   The current ROM's /vendor/lib64/libmtkcam_hal_aidl_device.so has
#   AidlCameraDevice::getTorchStrengthLevel() and turnOnTorchWithStrengthLevel()
#   compiled as STUBS that immediately `return -38` (ENOSYS). Because they report
#   "not implemented", Android hides the torch brightness slider. The DariaOS build
#   of the SAME file (identical ABI: same NEEDED libs, 0 new imports, 156==156
#   exported symbols) has the REAL implementation that calls the flash HAL.
#
# THIS MODULE overlays (magic mount), no partition is modified:
#   1. libcameracustom.flashlight.so  - 8-byte dual-LED patch (VERIFIED working)
#   2. libmtkcam_hal_aidl_device.so   - DariaOS build (real strength impl)
#   3. libmtkcam_metastore.so         - DariaOS build (reports strengthMaximumLevel>1)
#   4. libmtkcam_metadata.so          - DariaOS build (matching entry layout)
#
# NOTE: we deliberately do NOT swap the camera provider@2.6 HAL - that one has an
# A15/A16 vtable mismatch that crashes camerahalserver (invalid deviceId). The device
# layer is the correct, ABI-safe injection point.
SKIPUNZIP=0

ui_print "  *****************************************"
ui_print "  * VollaFlashDual v4.0                   *"
ui_print "  * Dual-LED + torch strength (RE fix)    *"
ui_print "  *****************************************"
ui_print " "

DEV=$(getprop ro.product.device)
ui_print "- Device: $DEV"
if [ "$DEV" != "algiz" ]; then
    ui_print "! Targets 'algiz' (Volla Quintus / zahedan). Yours: '$DEV'. Aborting."
    abort "! Wrong device."
fi

FL=/vendor/lib64/libcameracustom.flashlight.so
DEVLIB=/vendor/lib64/libmtkcam_hal_aidl_device.so
MS=/vendor/lib64/libmtkcam_metastore.so
MD=/vendor/lib64/libmtkcam_metadata.so
for f in "$FL" "$DEVLIB" "$MS" "$MD"; do
    [ -f "$f" ] || abort "! $f missing - unexpected ROM."
done

# flashlight patch must be size-identical to stock (it is an 8-byte patch)
S1=$(stat -c%s "$FL" 2>/dev/null || wc -c < "$FL")
S2=$(stat -c%s "$MODPATH/system/vendor/lib64/libcameracustom.flashlight.so")
ui_print "- flashlight stock=$S1 patched=$S2"
[ "$S1" = "$S2" ] || abort "! flashlight version mismatch - rebuild needed."

# device lib must be size-identical (Daria build is same size = same ABI generation)
D1=$(stat -c%s "$DEVLIB" 2>/dev/null || wc -c < "$DEVLIB")
D2=$(stat -c%s "$MODPATH/system/vendor/lib64/libmtkcam_hal_aidl_device.so")
ui_print "- aidl_device stock=$D1 daria=$D2"
if [ "$D1" != "$D2" ]; then
    ui_print "! aidl_device size differs from stock - your ROM build does not match"
    ui_print "! the Daria build this module was made against. Aborting to protect camera."
    abort "! aidl_device mismatch."
fi

# Back up all four stock files
BK=/data/local/tmp/vollaflashdual_backup
mkdir -p "$BK"
[ -f "$BK/flashlight.orig" ] || cp "$FL" "$BK/flashlight.orig"
[ -f "$BK/aidldevice.orig" ] || cp "$DEVLIB" "$BK/aidldevice.orig"
[ -f "$BK/metastore.orig" ]  || cp "$MS" "$BK/metastore.orig"
[ -f "$BK/metadata.orig" ]   || cp "$MD" "$BK/metadata.orig"
ui_print "- Stock libraries backed up to $BK"

for p in \
  "$MODPATH/system/vendor/lib64/libcameracustom.flashlight.so" \
  "$MODPATH/system/vendor/lib64/libmtkcam_hal_aidl_device.so" \
  "$MODPATH/system/vendor/lib64/libmtkcam_metastore.so" \
  "$MODPATH/system/vendor/lib64/libmtkcam_metadata.so" ; do
    set_perm "$p" 0 0 0644 u:object_r:vendor_file:s0
done

# reset boot-fail counter for the auto-recovery harness
rm -f /data/local/tmp/vollaflashdual_bootcount
ui_print " "
ui_print "- Installed. Reboot to activate."
ui_print "- After reboot: both LEDs light; long-press torch tile -> brightness slider."
ui_print " "
ui_print "- AUTO-RECOVERY: if the camera HAL crash-loops, the module disables itself"
ui_print "  automatically after 2 failed boots and restores stock libraries."
ui_print "- Manual recovery: adb shell su -c 'touch /data/local/tmp/vollaflashdual_disable'"
