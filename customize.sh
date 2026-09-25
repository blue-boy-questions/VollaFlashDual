#!/system/bin/sh
# VollaFlashDual customize.sh - runs at install time in KernelSU/Magisk
SKIPUNZIP=0

ui_print "  ***********************************"
ui_print "  * VollaFlashDual v1.0             *"
ui_print "  * Dual-LED flash for Volla Quintus*"
ui_print "  ***********************************"
ui_print " "

# Sanity: is this actually the algiz device?
DEV=$(getprop ro.product.device)
ui_print "- Detected device: $DEV"
if [ "$DEV" != "algiz" ]; then
    ui_print "! WARNING: this module targets 'algiz' (Volla Quintus)."
    ui_print "! Your device reports '$DEV'. Continuing anyway, but the"
    ui_print "! flash sysfs paths may differ and the module may do nothing."
fi

# Sanity: do both flash channels exist?
CH1=/sys/class/leds/mt6360_flash_ch1/brightness
CH2=/sys/class/leds/mt6360_flash_ch2/brightness
if [ -e "$CH1" ] && [ -e "$CH2" ]; then
    ui_print "- Found both flash channels (ch1 + ch2). Good."
else
    ui_print "! Could not find both flash channels right now."
    ui_print "! ch1 exists: $([ -e "$CH1" ] && echo yes || echo no)"
    ui_print "! ch2 exists: $([ -e "$CH2" ] && echo yes || echo no)"
    ui_print "! Installing anyway; the daemon waits for them at boot."
fi

ui_print "- Setting permissions"
set_perm "$MODPATH/service.sh" 0 0 0755

ui_print "- Done. Reboot to activate."
ui_print "- Both flash LEDs will light after reboot."
