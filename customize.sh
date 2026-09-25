#!/system/bin/sh
# VollaFlashDual v3.0 - install-time script (KernelSU / Magisk)
#
# Overlays TWO vendor libraries via magic mount:
#   1. libcameracustom.flashlight.so   - 8-byte patch: cust_isDualFlashSupport/
#      cust_isSubFlashSupport return 1 -> BOTH flash LEDs light.
#   2. hw/android.hardware.camera.provider@2.6-impl-mediatek.so - the DariaOS
#      build of the camera provider HAL, which implements torch strength
#      (getTorchStrengthLevel / turnOnTorchWithStrengthLevel / setTorchLevel)
#      and reports strengthMaximumLevel > 1 -> the brightness slider appears.
#
# ABI verified: the Daria provider needs only 2 extra imported symbols beyond
# the stock one, and both are already exported by the device's own
# libmtkcam_metastore.so and libmtkcam_metadata.so. No dependency chain needed.
SKIPUNZIP=0

ui_print "  ***************************************"
ui_print "  * VollaFlashDual v3.0                 *"
ui_print "  * Dual-LED flash + torch strength     *"
ui_print "  ***************************************"
ui_print " "

# 1. Device check
DEV=$(getprop ro.product.device)
ui_print "- Device: $DEV"
if [ "$DEV" != "algiz" ]; then
    ui_print "! This module targets 'algiz' (Volla Quintus). Yours is '$DEV'."
    ui_print "! The bundled libraries are build-specific; flashing on another"
    ui_print "! device/ROM can break the camera. Aborting to be safe."
    abort "! Wrong device."
fi

FL_STOCK=/vendor/lib64/libcameracustom.flashlight.so
PV_STOCK=/vendor/lib64/hw/android.hardware.camera.provider@2.6-impl-mediatek.so
FL_NEW=$MODPATH/system/vendor/lib64/libcameracustom.flashlight.so
PV_NEW=$MODPATH/system/vendor/lib64/hw/android.hardware.camera.provider@2.6-impl-mediatek.so

# 2. The flashlight patch is size-identical to stock; verify that.
if [ ! -f "$FL_STOCK" ]; then abort "! $FL_STOCK missing - unexpected ROM."; fi
S1=$(stat -c%s "$FL_STOCK" 2>/dev/null || wc -c < "$FL_STOCK")
S2=$(stat -c%s "$FL_NEW" 2>/dev/null || wc -c < "$FL_NEW")
ui_print "- flashlight stock=$S1 patched=$S2"
if [ "$S1" != "$S2" ]; then
    ui_print "! flashlight lib size mismatch - your ROM ships a different"
    ui_print "! build. The dual-LED patch was built for a specific version."
    abort "! flashlight version mismatch."
fi

# 3. The provider HAL is a cross-ROM swap (Daria). We CANNOT size-check it
#    against stock (they legitimately differ). Warn clearly.
if [ ! -f "$PV_STOCK" ]; then abort "! $PV_STOCK missing - unexpected ROM."; fi
ui_print "- Provider HAL will be replaced with the DariaOS build"
ui_print "  (adds torch strength). This is the higher-risk part."

# 4. Back up BOTH stock files.
BK=/data/local/tmp/vollaflashdual_backup
mkdir -p "$BK"
[ -f "$BK/flashlight.orig" ] || cp "$FL_STOCK" "$BK/flashlight.orig"
[ -f "$BK/provider.orig" ]   || cp "$PV_STOCK" "$BK/provider.orig"
ui_print "- Stock libraries backed up to $BK"

# 5. Permissions + SELinux label to match vendor files.
set_perm "$FL_NEW" 0 0 0644 u:object_r:vendor_file:s0
set_perm "$PV_NEW" 0 0 0644 u:object_r:vendor_file:s0

ui_print " "
ui_print "- Installed. Reboot to activate."
ui_print "- After reboot: both LEDs light, and long-pressing the torch"
ui_print "  tile should show a brightness slider."
ui_print " "
ui_print "- IF THE CAMERA BREAKS or you get a bootloop-free black camera:"
ui_print "    adb shell su -c 'touch /data/local/tmp/vollaflashdual_disable'"
ui_print "    then reboot - the module self-disables and restores stock."
