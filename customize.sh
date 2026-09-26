#!/system/bin/sh
# VollaFlashDual v2.0 - customize.sh (KernelSU / Magisk install-time script)
#
# Replaces /vendor/lib64/libcameracustom.flashlight.so with a binary-patched
# copy via magic mount. Only 8 bytes differ from stock: cust_isDualFlashSupport
# and cust_isSubFlashSupport now return 1 instead of 0, so the MediaTek camera
# HAL drives BOTH mt6360 flash channels natively.
SKIPUNZIP=0

ui_print "  *************************************"
ui_print "  * VollaFlashDual v2.0               *"
ui_print "  * Native dual-LED flash (HAL patch) *"
ui_print "  *************************************"
ui_print " "

ABORT_BADFILE() { ui_print "! $1"; abort "! Aborting to keep your system safe."; }

# 1. Device check
DEV=$(getprop ro.product.device)
ui_print "- Device: $DEV"
if [ "$DEV" != "algiz" ]; then
    ui_print "! WARNING: this module is built for 'algiz' (Volla Quintus)."
    ui_print "! Yours reports '$DEV'. The bundled library matches a specific"
    ui_print "! build; flashing on a different device/ROM can break the camera."
    ui_print "! If you are not sure, press Vol- now to abort."
fi

STOCK=/vendor/lib64/libcameracustom.flashlight.so
NEW=$MODPATH/system/vendor/lib64/libcameracustom.flashlight.so

# 2. The stock file must exist and be the same size we patched against.
if [ ! -f "$STOCK" ]; then
    ABORT_BADFILE "Stock $STOCK not found - unexpected ROM layout."
fi
STOCK_SIZE=$(stat -c%s "$STOCK" 2>/dev/null || wc -c < "$STOCK")
NEW_SIZE=$(stat -c%s "$NEW" 2>/dev/null || wc -c < "$NEW")
ui_print "- Stock lib size: $STOCK_SIZE"
ui_print "- Patched lib size: $NEW_SIZE"
if [ "$STOCK_SIZE" != "$NEW_SIZE" ]; then
    ui_print "! Stock library size does not match the patched one."
    ui_print "! Your ROM ships a different version of this HAL library."
    ui_print "! Flashing would replace it with an incompatible file and"
    ui_print "! could break the camera. Aborting."
    abort "! Version mismatch - not safe to flash."
fi

# 3. Back up the untouched stock library so the user can always restore it,
#    even outside this module.
BK=/data/local/tmp/vollaflashdual_backup
mkdir -p "$BK"
if [ ! -f "$BK/libcameracustom.flashlight.so.orig" ]; then
    cp "$STOCK" "$BK/libcameracustom.flashlight.so.orig"
    ui_print "- Backed up stock library to:"
    ui_print "  $BK/libcameracustom.flashlight.so.orig"
fi

# 4. Match ownership / SELinux context of the original so the overlay file is
#    labelled correctly when magic-mounted.
ui_print "- Setting permissions and SELinux context"
set_perm "$NEW" 0 0 0644 u:object_r:vendor_file:s0

ui_print " "
ui_print "- Installed. Reboot to activate."
ui_print "- After reboot BOTH flash LEDs light for camera + torch."
ui_print "- To revert: uninstall this module in KernelSU and reboot."
