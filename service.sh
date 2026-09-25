#!/system/bin/sh
# VollaFlashDual - KernelSU late_start service
#
# Problem: the stock MediaTek camera HAL only drives ONE flash LED
# (mt6360_flash_ch1). cust_isDualFlashSupport() is hard-coded to 0, so ch2
# never lights. Both channels work fine at the kernel level though.
#
# Fix: a tiny root daemon that continuously mirrors ch1's brightness onto ch2.
# Whenever anything (camera flash, torch, FlashDim) sets ch1, ch2 follows.
# Runs as root in the proper SELinux context, so it works regardless of
# SELinux enforcing/permissive and needs no Xposed.

MODDIR=${0%/*}

CH1=/sys/class/leds/mt6360_flash_ch1/brightness
CH2=/sys/class/leds/mt6360_flash_ch2/brightness
LOG=/data/local/tmp/vollaflashdual.log

# Wait for the LED sysfs nodes to appear (they show up after the flash driver
# probes; can lag a bit after boot).
i=0
while [ ! -w "$CH1" ] || [ ! -w "$CH2" ]; do
    sleep 2
    i=$((i+1))
    [ "$i" -gt 60 ] && { echo "$(date) nodes never appeared" >> "$LOG"; exit 1; }
done

echo "$(date) VollaFlashDual daemon starting" >> "$LOG"

last=""
# Poll ch1 and mirror to ch2. 40 ms is responsive enough for torch/flash
# without meaningful battery cost (single sysfs read).
while true; do
    v=$(cat "$CH1" 2>/dev/null)
    if [ -n "$v" ] && [ "$v" != "$last" ]; then
        echo "$v" > "$CH2" 2>/dev/null
        last="$v"
    fi
    sleep 0.04
done
