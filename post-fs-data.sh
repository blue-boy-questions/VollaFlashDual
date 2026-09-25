#!/system/bin/sh
# VollaFlashDual v4.0 post-fs-data - runs early each boot (before camera HAL starts).
#
# AUTO-RECOVERY HARNESS. Two mechanisms:
#
# 1. Manual disable flag: if the user created the disable flag over ADB, honour it
#    THEN CLEAR IT (fixes the v3.x bug where the flag stuck and the module stayed
#    disabled forever).
#
# 2. Boot-fail counter: increment a counter here (early boot). A late_start
#    service.sh (below) deletes it once the system reaches a healthy boot. If the
#    camera HAL crash-loops, the phone reboots before service.sh runs, so the
#    counter keeps climbing. At >=2 we self-disable and restore stock so the user
#    is never stuck with a broken camera.

MODDIR=${0%/*}
FLAG=/data/local/tmp/vollaflashdual_disable
COUNT=/data/local/tmp/vollaflashdual_bootcount
BK=/data/local/tmp/vollaflashdual_backup

restore_stock() {
    # copy backups back over the real vendor files if they are writable (they are on
    # a magic-mount system this is belt-and-suspenders; disabling the module is what
    # actually reverts the overlay)
    touch "$MODDIR/disable"
}

# --- mechanism 1: manual flag (honour once, then clear) ---
if [ -f "$FLAG" ]; then
    restore_stock
    rm -f "$FLAG"
    rm -f "$COUNT"
    exit 0
fi

# --- mechanism 2: boot-fail counter ---
n=0
[ -f "$COUNT" ] && n=$(cat "$COUNT" 2>/dev/null || echo 0)
n=$((n+1))
echo "$n" > "$COUNT"
if [ "$n" -ge 2 ]; then
    # two boots in a row without reaching healthy state -> assume crash loop
    restore_stock
    rm -f "$COUNT"
fi
